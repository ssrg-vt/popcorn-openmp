#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <getopt.h>
#include <omp.h>
#include "migrate.h"
#include "common.h"

int num_points = 5000000; /* number of vectors */
int num_means = 100;      /* number of clusters */
int dim = 3;              /* Dimension of each vector */
int grid_size = 1000;     /* size of each dimension of vector space */

int threads = 8;          /* Number of threads -- OpenMP runtime places them */

int *points;
int *means;
int *clusters;

bool ALIGN_TO_PAGE modified = true;

/**
 * dump_points()
 *  Helper function to print out the points
 */
void dump_points(int *vals, int rows)
{
  int i, j;

  for(i = 0; i < rows; i++) {
    for(j = 0; j < dim; j++)
      printf("%5d ",vals[i * dim + j]);
    printf("\n");
  }
}

/**
 * parse_args()
 *  Parse the user arguments
 */
void parse_args(int argc, char **argv) 
{
  int c;
  extern char *optarg;
  extern int optind;

  while((c = getopt(argc, argv, "d:c:p:s:t:h?")) != EOF) 
  {
    switch(c) {
      case 'd':
        dim = atoi(optarg);
        break;
      case 'c':
        num_means = atoi(optarg);
        break;
      case 'p':
        num_points = atoi(optarg);
        break;
      case 's':
        grid_size = atoi(optarg);
        break;
      case 't':
        threads = atoi(optarg);
        break;
      case 'h':
      case '?':
        printf("Usage: %s -d <vector dimension> -c <num clusters> "
            "-p <num points> -s <grid size> -t <threads>\n", argv[0]);
        exit(1);
    }
  }

  if(dim <= 0 || num_means <= 0 || num_points <= 0 || grid_size <= 0 ||
     threads < 1)
  {
    fprintf(stderr, "Illegal argument value. "
                    "All values must be numeric and greater than 0\n");
    exit(1);
  }

  printf("Dimension = %d\n", dim);
  printf("Number of clusters = %d\n", num_means);
  printf("Number of points = %d\n", num_points);
  printf("Size of each dimension = %d\n", grid_size);
  printf("Number of threads = %d\n", threads);
}

/**
 * generate_points()
 *  Generate the points
 */
void generate_points(int *pts, int size) 
{   
  int i, j;
  for(i=0; i<size; i++) 
    for(j=0; j<dim; j++) 
      pts[i * dim + j] = rand() % grid_size;
}

/**
 * get_sq_dist()
 *  Get the squared distance between 2 points
 */
static inline unsigned int get_sq_dist(int *v1, int *v2)
{
  int i;
  unsigned int sum = 0;
  for(i = 0; i < dim; i++) 
    sum += ((v1[i] - v2[i]) * (v1[i] - v2[i])); 
  return sum;
}

/**
 * add_to_sum()
 *  Helper function to update the total distance sum
 */
void add_to_sum(int *sum, int *point)
{
  int i;
  for(i = 0; i < dim; i++)
    sum[i] += point[i];   
}

static void main_loop()
{
  struct timeval start, end;
  printf("Starting iterative algorithm with %d threads\n\n", threads);
  omp_set_num_threads(threads);

  gettimeofday(&start, NULL);
  #pragma omp parallel
  {
    int i, j, min_idx, grp_size, iter = 0;
    unsigned int min_dist, cur_dist;
#ifdef _OPTIMIZED
    int *sum = popcorn_malloc_cur(sizeof(int) * dim);
#else
    int *sum = (int *)malloc(sizeof(int) * dim);
#endif

    /* Iterative loop */
    do {
      /* Ensure all threads enter loop with previous modified value */
      #pragma omp barrier

      /* Only one thread needs to reset modified */
      #pragma omp master
      {
        gettimeofday(&end, NULL);
        printf("%d: %lf seconds\n", iter++, stopwatch_elapsed(&start, &end));
        start = end;
        modified = false;
      }

      #pragma omp barrier

      /* Calculate closest cluster for each point */
      #pragma omp for reduction(|| : modified) schedule(runtime)
      for(i = 0; i < num_points; i++) 
      {
        min_dist = get_sq_dist(&points[i * dim], &means[0]);
        min_idx = 0; 
        for(j = 1; j < num_means; j++)
        {
          cur_dist = get_sq_dist(&points[i * dim], &means[j * dim]);
          if(cur_dist < min_dist) 
          {
            min_dist = cur_dist;
            min_idx = j;   
          }
        }

        if(clusters[i] != min_idx) 
        {
          clusters[i] = min_idx;
          modified = true;
        }
      }

      /* Update means as average of all member points */
      //#pragma omp for schedule(static)
      #pragma omp for schedule(runtime) nowait
      for(i = 0; i < num_means; i++) 
      {
        memset(sum, 0, dim * sizeof(int));
        grp_size = 0;
    
        for(j = 0; j < num_points; j++)
        {
          if(clusters[j] == i) 
          {
            add_to_sum(sum, &points[j * dim]);
            grp_size++;
          }   
        }
    
        if(grp_size != 0)
          for(j = 0; j < dim; j++)
            means[i * dim + j] = sum[j] / grp_size;
      }
    }
    while(modified);

    free(sum);
  }
}

int main(int argc, char **argv)
{
  struct timeval begin, end;

  parse_args(argc, argv);
  srand(0);

#ifdef _ALIGN_LAYOUT
  int ret;
  ret = posix_memalign((void **)&points, PAGESZ, sizeof(int) * num_points * dim);
  ret |= posix_memalign((void **)&means, PAGESZ, sizeof(int) * num_means * dim);
  ret |= posix_memalign((void **)&clusters, PAGESZ, sizeof(int) * num_points);
  if(ret) {
    perror("Could not allocate aligned application memory");
    exit(1);
  }
#else
  points = (int *)malloc(sizeof(int) * num_points * dim);
  means = (int *)malloc(sizeof(int) * num_means * dim);
  clusters = (int *)malloc(sizeof(int) * num_points);
#endif
  printf("Generating points\n");
  generate_points(points, num_points);
  printf("Generating means\n");
  generate_points(means, num_means);
  memset(clusters, -1, sizeof(int) * num_points);

  printf("Memory: points=%p means=%p clusters=%p\n", points, means, clusters);

  gettimeofday(&begin, NULL);
  main_loop();
  gettimeofday(&end, NULL);

  printf("\n\nFinal means:\n");
  dump_points(means, num_means);
  printf("kmeans: Completed %.6lf\n\n", stopwatch_elapsed(&begin, &end));

  free(points);
  free(means);
  free(clusters);

  return 0;
}
