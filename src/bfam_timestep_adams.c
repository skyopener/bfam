#include <bfam_timestep_adams.h>
#include <bfam_log.h>

#define BFAM_ADAMS_PREFIX ("_adams_rate_")

bfam_ts_adams_t*
bfam_ts_adams_new(bfam_domain_t* dom, bfam_ts_adams_method_t method,
    bfam_domain_match_t subdom_match, const char** subdom_tags,
    bfam_domain_match_t comm_match, const char** comm_tags,
    MPI_Comm mpicomm, int mpitag, void *comm_data,
    void (*aux_rates) (bfam_subdomain_t *thisSubdomain, const char *prefix),
    void (*intra_rhs) (bfam_subdomain_t *thisSubdomain,
      const char *rate_prefix, const char *field_prefix,
      const bfam_long_real_t t),
    void (*inter_rhs) (bfam_subdomain_t *thisSubdomain,
      const char *rate_prefix, const char *field_prefix,
      const bfam_long_real_t t),
    void (*add_rates) (bfam_subdomain_t *thisSubdomain,
      const char *field_prefix_lhs, const char *field_prefix_rhs,
      const char *rate_prefix, const bfam_long_real_t a))
{
  bfam_ts_adams_t* newTS = bfam_malloc(sizeof(bfam_ts_adams_t));
  bfam_ts_adams_init(newTS, dom, method, subdom_match, subdom_tags,
      comm_match, comm_tags, mpicomm, mpitag, comm_data, aux_rates,
      intra_rhs,inter_rhs,add_rates);
  return newTS;
}


void
bfam_ts_adams_init(bfam_ts_adams_t* ts,
    bfam_domain_t* dom, bfam_ts_adams_method_t method,
    bfam_domain_match_t subdom_match, const char** subdom_tags,
    bfam_domain_match_t comm_match, const char** comm_tags,
    MPI_Comm mpicomm, int mpitag, void *comm_data,
    void (*aux_rates) (bfam_subdomain_t *thisSubdomain, const char *prefix),
    void (*intra_rhs) (bfam_subdomain_t *thisSubdomain,
      const char *rate_prefix, const char *field_prefix,
      const bfam_long_real_t t),
    void (*inter_rhs) (bfam_subdomain_t *thisSubdomain,
      const char *rate_prefix, const char *field_prefix,
      const bfam_long_real_t t),
    void (*add_rates) (bfam_subdomain_t *thisSubdomain,
      const char *field_prefix_lhs, const char *field_prefix_rhs,
      const char *rate_prefix, const bfam_long_real_t a))
{
  BFAM_LDEBUG("ADAMS INIT");

  /*
   * set up some preliminaries
   */
  bfam_ts_init(&ts->base, dom);
  bfam_dictionary_init(&ts->elems);
  ts->t  = BFAM_LONG_REAL(0.0);
  /* ts->base.step = &bfam_ts_adams_step; */

  /*
   * store the function calls
   */
  ts->intra_rhs   = intra_rhs;
  ts->inter_rhs   = inter_rhs;
  ts->add_rates   = add_rates;

  switch(method)
  {
    default:
      BFAM_WARNING("Invalid Adams scheme, using ADAMS_3");
    case BFAM_TS_ADAMS_3:
      ts->nStages = 3;
      ts->A = bfam_malloc_aligned(ts->nStages*sizeof(bfam_long_real_t));

      ts->A[0] = BFAM_LONG_REAL(23)/
                 BFAM_LONG_REAL(12);
      ts->A[1] = BFAM_LONG_REAL(-4)/
                 BFAM_LONG_REAL( 3);
      ts->A[2] = BFAM_LONG_REAL( 5)/
                 BFAM_LONG_REAL(12);

      break;
    case BFAM_TS_ADAMS_1:
      ts->nStages = 1;
      ts->A = bfam_malloc_aligned(ts->nStages*sizeof(bfam_long_real_t));

      ts->A[0] = BFAM_LONG_REAL(1);
      break;
    case BFAM_TS_ADAMS_2:
      ts->nStages = 2;
      ts->A = bfam_malloc_aligned(ts->nStages*sizeof(bfam_long_real_t));

      ts->A[0] = BFAM_LONG_REAL( 3)/
                 BFAM_LONG_REAL( 2);
      ts->A[1] = BFAM_LONG_REAL(-1)/
                 BFAM_LONG_REAL( 2);
      break;
    case BFAM_TS_ADAMS_4:
      ts->nStages = 4;
      ts->A = bfam_malloc_aligned(ts->nStages*sizeof(bfam_long_real_t));

      ts->A[0] = BFAM_LONG_REAL( 55)/
                 BFAM_LONG_REAL( 24);
      ts->A[1] = BFAM_LONG_REAL(-59)/
                 BFAM_LONG_REAL( 24);
      ts->A[2] = BFAM_LONG_REAL( 37)/
                 BFAM_LONG_REAL( 24);
      ts->A[3] = BFAM_LONG_REAL(  3)/
                 BFAM_LONG_REAL(  8);
      break;
  }

  /*
   * get the subdomains and create rates we will need
   */
   bfam_subdomain_t *subs[dom->numSubdomains+1];
   bfam_locidx_t numSubs = 0;
   bfam_domain_get_subdomains(dom,subdom_match,subdom_tags,
       dom->numSubdomains,subs,&numSubs);
   for(int s = 0; s < numSubs;s++)
   {
     int rval = bfam_dictionary_insert_ptr(&ts->elems,subs[s]->name,subs[s]);
     BFAM_ABORT_IF_NOT(rval != 1, "Issue adding subdomain %s", subs[s]->name);

     for(int n = 0; n < ts->nStages; n++)
     {
       char aux_rates_name[BFAM_BUFSIZ];
       snprintf(aux_rates_name,BFAM_BUFSIZ,"%s_%d_",BFAM_ADAMS_PREFIX,n);
       aux_rates(subs[s],aux_rates_name);
     }
   }

  /*
   * Set up the communicator we will use
   */
   ts->comm = bfam_communicator_new(dom,comm_match,comm_tags,mpicomm,mpitag,
       comm_data);
}

void
bfam_ts_adams_free(bfam_ts_adams_t* ts)
{
  BFAM_LDEBUG("ADMAS FREE");
  bfam_communicator_free(ts->comm);
  bfam_free(ts->comm);
  ts->comm = NULL;
  bfam_dictionary_clear(&ts->elems);
  bfam_free_aligned(ts->A);
  ts->A = NULL;
  ts->nStages = 0;
  ts->t  = NAN;
  bfam_ts_free(&ts->base);
}

void
bfam_ts_adams_set_time(bfam_ts_adams_t* ts,bfam_long_real_t time)
{
  ts->t = time;
}

bfam_long_real_t
bfam_ts_adams_get_time(bfam_ts_adams_t* ts)
{
  return ts->t;
}
