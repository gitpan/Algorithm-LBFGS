/**************************************************************************
 * XS of Algorithm::LBFGS
 * -> by Laye Suen
 **************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "lbfgs.h"

/* Macros for debugging */

/* uncomment the line below to enable tracing and timing */
/*#define __ENABLE_TRACING__*/

#ifdef __ENABLE_TRACING__

#include "time.h"

#define TRACE(msg) \
    printf(_fn); printf(": "); printf(msg); \
    printf(": %0.10f s\n", 1.0 * (clock() - _t) / CLOCKS_PER_SEC); \
    fflush(stdout); _t = clock()
#define dTRACE(fn) clock_t _t = clock(); char* _fn = fn

#else

#define TRACE(msg)
#define dTRACE

#endif

/* Other macros */

#define newSVpv_(x) newSVpv(x, strlen(x))
#define hv_store_(hv, key, value) \
    hv_store(hv, key, strlen(key), value, 0)

/**************************************************************************
 * NON-EXPORTED SUBS
 **************************************************************************/

/* Evaluation callback for calling Perl callback */
lbfgsfloatval_t pl_eval_cb(
    void*                    instance,
    const lbfgsfloatval_t*   x,
    lbfgsfloatval_t*         g,
    const int                n,
    const lbfgsfloatval_t    step)
{
    int i;
    SV *lbfgs_eval, *user_data, *sv_f;
    AV *av_x, *av_g;
    lbfgsfloatval_t f;
    dSP;
    dTRACE("pl_eval_cb");
    /* fetch refs to user evaluation callback and extra data */
    TRACE("enter");
    lbfgs_eval = ((SV**)instance)[-2];
    user_data = ((SV**)instance)[0];
    /* create an AV av_x from the C array x */
    av_x = newAV();
    av_extend(av_x, n - 1);
    for (i = 0; i < n; i++) av_store(av_x, i, newSVnv(x[i]));
    /* call the user evaluation callback */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_noinc((SV*)av_x)));
    XPUSHs(sv_2mortal(newSVnv(step)));
    XPUSHs(user_data);
    PUTBACK;
    TRACE("finish arguments preparation");
    call_sv(lbfgs_eval, G_ARRAY);
    TRACE("finish calling");
    SPAGAIN;
    av_g = (AV*)SvRV(POPs);
    sv_f = POPs;
    f = SvNV(sv_f);
    for (i = 0; i < n; i++)
        g[i] = SvNV(*av_fetch(av_g, i, 0));
    PUTBACK;
    FREETMPS;
    LEAVE;
    /* clean up (for non-mortal return values) */
    while (SvREFCNT(av_g) > 0) { av_undef(av_g); }
    while (SvREFCNT(sv_f) > 0) { SvREFCNT_dec(sv_f); }
    TRACE("leave");
    return f;
}

/* Progress callback for calling Perl callback */
int pl_prgr_cb(
    void*                    instance,
    const lbfgsfloatval_t*   x,
    const lbfgsfloatval_t*   g,
    const lbfgsfloatval_t    fx,
    const lbfgsfloatval_t    xnorm,
    const lbfgsfloatval_t    gnorm,
    const lbfgsfloatval_t    step,
    int                      n,
    int                      k,
    int                      ls)
{
    int i, r;
    SV *lbfgs_prgr, *user_data, *sv_r;
    AV *av_x, *av_g;
    dSP;
    dTRACE("pl_prgr_cb");
    /* fetch refs to the user progress callback and extra data */
    TRACE("enter");
    lbfgs_prgr = ((SV**)instance)[-1];
    user_data = ((SV**)instance)[0];
    /* create AVs for C array x and g */
    av_x = newAV();
    for (i = 0; i < n; i++) av_store(av_x, i, newSVnv(x[i]));
    av_g = newAV();
    for (i = 0; i < n; i++) av_store(av_g, i, newSVnv(g[i]));
    /* call the user progress callback */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_noinc((SV*)av_x)));
    XPUSHs(sv_2mortal(newRV_noinc((SV*)av_g)));
    XPUSHs(sv_2mortal(newSVnv(fx)));
    XPUSHs(sv_2mortal(newSVnv(xnorm)));
    XPUSHs(sv_2mortal(newSVnv(gnorm)));
    XPUSHs(sv_2mortal(newSVnv(step)));
    XPUSHs(sv_2mortal(newSViv(k)));
    XPUSHs(sv_2mortal(newSViv(ls)));
    XPUSHs(user_data);
    PUTBACK;
    TRACE("finish arguments preparation");
    call_sv(lbfgs_prgr, G_ARRAY);
    TRACE("finish calling");
    SPAGAIN;
    sv_r = POPs;
    r = SvIV(sv_r);
    PUTBACK;
    FREETMPS;
    LEAVE;
    /* clean up (for non-mortal return values) */
    while (SvREFCNT(sv_r) > 0) { SvREFCNT_dec(sv_r); }
    TRACE("leave");
    return r;
}

int logging_prgr_cb(
    void*                    user_data,
    const lbfgsfloatval_t*   x,
    const lbfgsfloatval_t*   g,
    const lbfgsfloatval_t    fx,
    const lbfgsfloatval_t    xnorm,
    const lbfgsfloatval_t    gnorm,
    const lbfgsfloatval_t    step,
    int                      n,
    int                      k,
    int                      ls)
{
    AV* log = (AV*)SvRV(((SV**)user_data)[0]);
    HV* item = newHV();
    AV* av_x = newAV();
    AV* av_g = newAV();
    int i;
    av_extend(av_x, n - 1);
    av_extend(av_g, n - 1);
    for (i = 0; i < n; i++) av_store(av_x, i, newSVnv(x[i]));
    for (i = 0; i < n; i++) av_store(av_g, i, newSVnv(g[i]));
    hv_store_(item, "x", newRV_noinc((SV*)av_x));
    hv_store_(item, "g", newRV_noinc((SV*)av_g));
    hv_store_(item, "fx", newSVnv(fx));
    hv_store_(item, "xnorm", newSVnv(xnorm));
    hv_store_(item, "gnorm", newSVnv(gnorm));
    hv_store_(item, "step", newSVnv(step));
    hv_store_(item, "n", newSViv(n));
    hv_store_(item, "k", newSViv(k));
    hv_store_(item, "ls", newSViv(ls));
    av_push(log, newRV_noinc((SV*)item));
    return 0;
}

int verbose_prgr_cb(
    void*                    instance,
    const lbfgsfloatval_t*   x,
    const lbfgsfloatval_t*   g,
    const lbfgsfloatval_t    fx,
    const lbfgsfloatval_t    xnorm,
    const lbfgsfloatval_t    gnorm,
    const lbfgsfloatval_t    step,
    int                      n,
    int                      k,
    int                      ls)
{
    printf("%d: fx = %g, xnorm = %g, gnorm = %g\n", k, fx, xnorm, gnorm);
    return 0;
}

/**************************************************************************
 * EXPORTED XSUBS
 **************************************************************************/
MODULE = Algorithm::LBFGS		PACKAGE = Algorithm::LBFGS

void*
create_lbfgs_instance(lbfgs_eval, lbfgs_prgr, user_data)
        SV*     lbfgs_eval
	    SV*     lbfgs_prgr
	    SV*	user_data
    PREINIT:
        void* instance = malloc(3 * sizeof(SV*));
    CODE:
        ((SV**)instance)[0] = lbfgs_eval; /* ref to eval callback */
	    ((SV**)instance)[1] = lbfgs_prgr; /* ref to monitor callback */
	    ((SV**)instance)[2] = user_data;  /* ref to user data */
	    RETVAL = instance;
    OUTPUT:
        RETVAL

void
destroy_lbfgs_instance(li)
        void*   li
    CODE:
        free(li);


void*
create_lbfgs_param()
    PREINIT:
        void* lp = malloc(sizeof(lbfgs_parameter_t));
    CODE:
        lbfgs_parameter_init((lbfgs_parameter_t*)lp);
	    RETVAL = lp;
    OUTPUT:
        RETVAL

void
destroy_lbfgs_param(lp)
        void*   lp
    CODE:
        free(lp);

SV*
set_lbfgs_param(lp, name, val)
        void*   lp
	    char*   name
	    SV*     val
    PREINIT:
        lbfgs_parameter_t* p = (lbfgs_parameter_t*)lp;
	    SV* r = &PL_sv_undef;
    CODE:
        if (strcmp(name, "m") == 0) {
	        if (SvIOK(val)) p->m = SvIV(val);
	        r = newSViv(p->m);
	    }
	    else if (strcmp(name, "epsilon") == 0) {
	        if (SvNOK(val)) p->epsilon = SvNV(val);
	        r = newSVnv(p->epsilon);
	    }
	    else if (strcmp(name, "max_iterations") == 0) {
	        if (SvIOK(val)) p->max_iterations = SvIV(val);
	        r = newSViv(p->max_iterations);
	    }
	    else if (strcmp(name, "max_linesearch") == 0) {
	        if (SvIOK(val)) p->max_linesearch = SvIV(val);
	        r = newSViv(p->max_linesearch);
	    }
	    else if (strcmp(name, "min_step") == 0) {
	        if (SvNOK(val)) p->min_step = SvNV(val);
	        r = newSVnv(p->min_step);
	    }
	    else if (strcmp(name, "max_step") == 0) {
	        if (SvNOK(val)) p->max_step = SvNV(val);
	        r = newSVnv(p->max_step);
	    }
	    else if (strcmp(name, "ftol") == 0) {
	        if (SvNOK(val)) p->ftol = SvNV(val);
	        r = newSVnv(p->ftol);
	    }
	    else if (strcmp(name, "gtol") == 0) {
	        if (SvNOK(val)) p->gtol = SvNV(val);
	        r = newSVnv(p->gtol);
	    }
	    else if (strcmp(name, "xtol") == 0) {
	        if (SvNOK(val)) p->xtol = SvNV(val);
	        r = newSVnv(p->xtol);
	    }
	    else if (strcmp(name, "orthantwise_c") == 0) {
	        if (SvNOK(val)) p->orthantwise_c = SvNV(val);
	        r = newSVnv(p->orthantwise_c);
	    }
	    RETVAL = r;
    OUTPUT:
        RETVAL

SV*
do_lbfgs(param, instance, x0)
        void*   param
	    void*   instance
	    SV*     x0
    PREINIT:
        AV* av_x0 = (AV*)SvRV(x0);
	    int n = av_len(av_x0) + 1;
	    int i, s;
	    lbfgsfloatval_t* carr_x0 = (lbfgsfloatval_t*)
	        malloc(n * sizeof(lbfgsfloatval_t));
	    SV* eval_cb = ((SV**)instance)[0];
	    SV* prgr_cb = ((SV**)instance)[1];
	    void *eval_cb_ptr, *prgr_cb_ptr, *user_data_ptr;
    CODE:
	    /* build C array carr_x0 from Perl array ref x0 */
	    for (i = 0; i < n; i++) carr_x0[i] = SvNV(*av_fetch(av_x0, i, 0));
	    /* fill eval_cb_ptr */
	    if (!SvOK(eval_cb))
	        eval_cb_ptr = NULL;
	    else if (SvROK(eval_cb))
	        eval_cb_ptr = &pl_eval_cb;
	    else if (SvIOK(eval_cb) && SvIV(eval_cb) != 0)
	        eval_cb_ptr = INT2PTR(void*, SvIV(eval_cb));
	    else
	        eval_cb_ptr = NULL;
	    /* fill prgr_cb_ptr */    
	    if (!SvOK(prgr_cb))
	        prgr_cb_ptr = NULL;
	    else if (SvROK(prgr_cb))
	        prgr_cb_ptr = &pl_prgr_cb;
	    else if (SvIOK(prgr_cb) && SvIV(prgr_cb) != 0)
	        prgr_cb_ptr = INT2PTR(void*, SvIV(prgr_cb));
	    else
	        prgr_cb_ptr = NULL;
	    /* call L-BFGS */
	    s = lbfgs(n, carr_x0, NULL, eval_cb_ptr, prgr_cb_ptr,
		          &(((SV**)instance)[2]), (lbfgs_parameter_t*)param);
        /* store the result back to the Perl array ref x0 */
	    for (i = 0; i < n; i++) av_store(av_x0, i, newSVnv(carr_x0[i]));
	    /* release the C array */
	    free(carr_x0);
	    RETVAL = newSViv(s);
    OUTPUT:
        RETVAL

void*
logging_prgr_cb_ptr()
    CODE:
        RETVAL = &logging_prgr_cb;
    OUTPUT:
        RETVAL

void*
verbose_prgr_cb_ptr()
    CODE:
        RETVAL = &verbose_prgr_cb;
    OUTPUT:
        RETVAL

SV*
status_2pv(status)
        int     status
    CODE:
        switch (status) {
	    case 0:
	        RETVAL = newSVpv_("LBFGS_OK"); break;
	    case LBFGSERR_UNKNOWNERROR:
	        RETVAL = newSVpv_("LBFGSERR_UNKNOWNERROR"); break;
	    case LBFGSERR_LOGICERROR:
	        RETVAL = newSVpv_("LBFGSERR_LOGICERROR"); break;
	    case LBFGSERR_OUTOFMEMORY:
	        RETVAL = newSVpv_("LBFGSERR_OUTOFMEMORY"); break;
	    case LBFGSERR_CANCELED:
	        RETVAL = newSVpv_("LBFGSERR_CANCELED"); break;
	    case LBFGSERR_INVALID_N:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_N"); break;
	    case LBFGSERR_INVALID_N_SSE:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_N_SSE"); break;
	    case LBFGSERR_INVALID_MINSTEP:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_MINSTEP"); break;
	    case LBFGSERR_INVALID_MAXSTEP:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_MAXSTEP"); break;
	    case LBFGSERR_INVALID_FTOL:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_FTOL"); break;
	    case LBFGSERR_INVALID_GTOL:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_GTOL"); break;
	    case LBFGSERR_INVALID_XTOL:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_XTOL"); break;
	    case LBFGSERR_INVALID_MAXLINESEARCH:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_MAXLINESEARCH"); break;
	    case LBFGSERR_INVALID_ORTHANTWISE:
	        RETVAL = newSVpv_("LBFGSERR_INVALID_ORTHANTWISE"); break;
	    case LBFGSERR_OUTOFINTERVAL:
	        RETVAL = newSVpv_("LBFGSERR_OUTOFINTERVAL"); break;
	    case LBFGSERR_INCORRECT_TMINMAX:
	        RETVAL = newSVpv_("LBFGSERR_INCORRECT_TMINMAX"); break;
	    case LBFGSERR_ROUNDING_ERROR:
	        RETVAL = newSVpv_("LBFGSERR_ROUNDING_ERROR"); break;
	    case LBFGSERR_MINIMUMSTEP:
	        RETVAL = newSVpv_("LBFGSERR_MINIMUMSTEP"); break;
	    case LBFGSERR_MAXIMUMSTEP:
	        RETVAL = newSVpv_("LBFGSERR_MAXIMUMSTEP"); break;
	    case LBFGSERR_MAXIMUMLINESEARCH:
	        RETVAL = newSVpv_("LBFGSERR_MAXIMUMLINESEARCH"); break;
	    case LBFGSERR_MAXIMUMITERATION:
	        RETVAL = newSVpv_("LBFGSERR_MAXIMUMITERATION"); break;
	    case LBFGSERR_WIDTHTOOSMALL:
	        RETVAL = newSVpv_("LBFGSERR_WIDTHTOOSMALL"); break;
	    case LBFGSERR_INVALIDPARAMETERS:
	        RETVAL = newSVpv_("LBFGSERR_INVALIDPARAMETERS"); break;
	    case LBFGSERR_INCREASEGRADIENT:
	        RETVAL = newSVpv_("LBFGSERR_INCREASEGRADIENT"); break;
	    default:
	        RETVAL = newSVpv_(""); break;
	    }
    OUTPUT:
        RETVAL

