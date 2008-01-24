/**************************************************************************
 * XS of Algorithm::LBFGS
 * -> by Laye Suen
 **************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "lbfgs.h"

#define newSVpv_(x) newSVpv(x, strlen(x))

/**************************************************************************
 * NON-EXPORTED SUBS
 **************************************************************************/

/* Call a perl subroutine pointed by sub_ref in an ARRAY context,
 * the SVs returned in rets should be release manually */
void call_perl_sub(
    SV*                      sub_ref,
    SV**                     args,
    SV**                     rets,
    int                      nargs,
    int                      nrets)
{
    int i;
    /* initialize */
    dSP;
    ENTER;
    SAVETMPS;
    /* push arguments into the Perl stack */
    PUSHMARK(SP);
    for (i = 0; i < nargs; i++) XPUSHs(args[i]);
    PUTBACK;
    /* call */
    call_sv(sub_ref, G_ARRAY);
    /* get return values from the Perl stack */
    SPAGAIN;
    for (i = nrets - 1; i >= 0; i--) rets[i] = newSVsv(POPs);
    PUTBACK;
    /* finalize */
    FREETMPS;
    LEAVE;
}

/* Evaluating callback for L-BFGS */
lbfgsfloatval_t lbfgs_evaluate(
    void*                    instance,
    const lbfgsfloatval_t*   x,
    lbfgsfloatval_t*         g,
    const int                n,
    const lbfgsfloatval_t    step)
{
    int i;
    /* fetch refs to user evaluating sub and extra data */
    SV* lbfgs_eval = ((SV**)instance)[0];
    SV* user_data = ((SV**)instance)[2];
    /* create an mortal AV av_x from the C array x */
    AV* av_x = (AV*)sv_2mortal((SV*)newAV());
    av_extend(av_x, n - 1);
    for (i = 0; i < n; i++) av_store(av_x, i, newSVnv(x[i]));
    /* allocate space for arguments and return values */
    SV** args = (SV**)malloc(3 * sizeof(SV*));
    SV** rets = (SV**)malloc(2 * sizeof(SV*));
    /* call the user evaluating sub */
    args[0] = sv_2mortal(newRV_inc((SV*)av_x));
    args[1] = sv_2mortal(newSVnv(step));
    args[2] = user_data;
    call_perl_sub(lbfgs_eval, args, rets, 3, 2);
    /* get the function value and gradient vector from return values */
    for (i = 0; i < n; i++)
        g[i] = SvNV(*av_fetch((AV*)SvRV(rets[1]), i, 0));
    lbfgsfloatval_t f = SvNV(rets[0]);
    /* release space of arguments and return values */
    SvREFCNT_dec(rets[0]);
    SvREFCNT_dec(rets[1]);
    free(args);
    free(rets);
    return f;
}

/* Progress monitor callback for L-BFGS */
int lbfgs_progress(
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
    int i;
    /* fetch refs to the user progress monitor sub and extra data */
    SV* lbfgs_prgr = ((SV**)instance)[1];
    SV* user_data = ((SV**)instance)[2];
    /* create mortal AVs for C array x and g */
    AV* av_x = (AV*)sv_2mortal((SV*)newAV());
    for (i = 0; i < n; i++) av_store(av_x, i, newSVnv(x[i]));
    AV* av_g = (AV*)sv_2mortal((SV*)newAV());
    for (i = 0; i < n; i++) av_store(av_g, i, newSVnv(g[i]));
    /* allocate space for arguments and return values */
    SV** args = (SV**)malloc(9 * sizeof(SV*));
    SV** rets = (SV**)malloc(1 * sizeof(SV*));
    /* call the user progress monitor sub */
    args[0] = sv_2mortal(newRV_inc((SV*)av_x));
    args[1] = sv_2mortal(newRV_inc((SV*)av_g));
    args[2] = sv_2mortal(newSVnv(fx));
    args[3] = sv_2mortal(newSVnv(xnorm));
    args[4] = sv_2mortal(newSVnv(gnorm));
    args[5] = sv_2mortal(newSVnv(step));
    args[6] = sv_2mortal(newSViv(k));
    args[7] = sv_2mortal(newSViv(ls));
    args[8] = user_data;
    call_perl_sub(lbfgs_prgr, args, rets, 9, 1);
    /* get status from return value */
    int r = SvIV(rets[0]);
    /* release space of arguments and return values */
    SvREFCNT_dec(rets[0]);
    free(args);
    free(rets);
    return r;
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
    CODE:
        void* instance = malloc(3 * sizeof(SV*));
        ((SV**)instance)[0] = lbfgs_eval; /* ref to Perl eval callback */
	((SV**)instance)[1] = lbfgs_prgr; /* ref to Perl monitor callback */
	((SV**)instance)[2] = user_data;  /* ref to Perl user data */
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
    CODE:
        void* lp = malloc(sizeof(lbfgs_parameter_t));
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
    CODE:
        lbfgs_parameter_t* p = (lbfgs_parameter_t*)lp;
	SV* r = &PL_sv_undef;
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
    CODE:
	/* build C array carr_x0 from Perl array ref x0 */
        AV* av_x0 = (AV*)SvRV(x0);
	int n = av_len(av_x0) + 1;
	lbfgsfloatval_t* carr_x0 = (lbfgsfloatval_t*)
	    malloc(n * sizeof(lbfgsfloatval_t));
	int i;
	for (i = 0; i < n; i++) carr_x0[i] = SvNV(*av_fetch(av_x0, i, 0));
	/* call L-BFGS */
	int s = lbfgs(n, carr_x0, NULL, 
	              SvOK(((SV**)instance)[0]) ? &lbfgs_evaluate : NULL,
	              SvOK(((SV**)instance)[1]) ? &lbfgs_progress : NULL,
	              instance, (lbfgs_parameter_t*)param);
        /* store the result back to the Perl array ref x0 */
	for (i = 0; i < n; i++) av_store(av_x0, i, newSVnv(carr_x0[i]));
	/* release the C array */
	free(carr_x0);
	RETVAL = newSViv(s);
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

