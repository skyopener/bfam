#include <bfam.h>

static void
test_create()
{
  // domain test
  bfam_domain_t  domain1;
  bfam_domain_t* domain2;

  // Test init domain
  bfam_domain_init(&domain1,NULL);

  // Test new domain
  domain2 = bfam_domain_new(NULL);

  // free a domain
  bfam_domain_free(&domain1);
  bfam_domain_free( domain2);
  bfam_free(domain2);
}

static void
test_insert()
{
  // domain test
  bfam_domain_t* domain;

  // Test new domain
  domain = bfam_domain_new(NULL);

  static const char *elems[] =
      {"a", "aa", "b", "bb", "ab", "ba", "aba", "bab",
        "a1", "a2", "a3", "a4", "a5", "a6", "a7",
        "a9", "a10", "a11", "a12", "a13", "a14", "a15",
        NULL};

  for (unsigned i = 0; elems[i]; ++i)
  {
    bfam_subdomain_t* newSub = bfam_malloc(sizeof(bfam_subdomain_t));
    bfam_subdomain_init(newSub,elems[i]);
    bfam_domain_add_subdomain(domain,newSub);

    bfam_subdomain_add_tag(newSub, "testing 1 2 3");
    bfam_subdomain_add_tag(newSub, elems[i]);
    bfam_subdomain_add_tag(newSub, "try");

    BFAM_ABORT_IF(bfam_subdomain_has_tag(newSub, "bad tag"),
        "Error finding tag: bad tag");
    BFAM_ABORT_IF_NOT(bfam_subdomain_has_tag(newSub, "try"),
        "Error finding tag: try");
    BFAM_ABORT_IF_NOT(bfam_subdomain_has_tag(newSub, elems[i]),
        "Error finding tag: %s", elems[i]);

    BFAM_ABORT_IF_NOT(bfam_subdomain_delete_tag(newSub, "try"),
        "Error removing tag: try");
    BFAM_ABORT_IF(bfam_subdomain_has_tag(newSub, "try"),
        "Error finding tag: try");
  }

  bfam_subdomain_t **matchedSubdomains =
    bfam_malloc(domain->numSubdomains*sizeof(bfam_subdomain_t*));
  bfam_locidx_t numMatchedSubdomains;

  const char *tags1[] = {"a11", "a10", "b"};
  bfam_domain_get_subdomains(domain, BFAM_DOMAIN_OR, 3, tags1,
    domain->numSubdomains, matchedSubdomains, &numMatchedSubdomains);
  BFAM_ABORT_IF(numMatchedSubdomains != 3, "Error matching tags1: %jd",
      (intmax_t) numMatchedSubdomains);

  const char *tags2[] = {"a11", "testing 1 2 3"};
  bfam_domain_get_subdomains(domain, BFAM_DOMAIN_AND, 2, tags2,
    domain->numSubdomains, matchedSubdomains, &numMatchedSubdomains);
  BFAM_ABORT_IF(numMatchedSubdomains != 1, "Error matching tags2: %jd",
      (intmax_t) numMatchedSubdomains);


  bfam_free(matchedSubdomains);
  // free a domain
  bfam_domain_free(domain);
  bfam_free(domain);
}

int
main (int argc, char *argv[])
{
  test_create();
  test_insert();

  return EXIT_SUCCESS;
}
