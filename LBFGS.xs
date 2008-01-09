#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

extern struct { long e_1[2]; double e_2[3]; } lb3_;

void MAIN__() {}

MODULE = Algorithm::LBFGS		PACKAGE = Algorithm::LBFGS		


double
eps()
    CODE:
        RETVAL = DBL_EPSILON;
    OUTPUT:
        RETVAL

void*
alloc_workspace(n, m)
        long    n
	long    m
    CODE:
        long size = n * (2 * m + 1) + 2 * m;
        RETVAL = malloc(size * sizeof(double));
    OUTPUT:
        RETVAL

void
free_workspace(w)
        void*   w
    CODE:
        free(w);

void
set_gtol(gtol)
        double  gtol
    CODE:
	lb3_.e_2[0] = gtol;

void
set_stpmin(stpmin)
        double  stpmin
    CODE:
	lb3_.e_2[1] = stpmin;

void
set_stpmax(stpmax)
        double  stpmax
    CODE:
	lb3_.e_2[2] = stpmax;

void
lbfgs_step(n, m, x, f, g, diagco, diag, iprt1, iprt2, eps, xtol, w, iflag)
        long    n
        long    m
        AV*     x
        double  f
        AV*     g
        long    diagco
        AV*     diag
        long    iprt1
        long    iprt2
        double  eps
        double  xtol
        void*   w
        SV*     iflag
    CODE:
        /* prepare for the call */
        long i;
        double* x_ = malloc(n * sizeof(double));
        for (i = 0; i < n; i++) x_[i] = SvNV(*av_fetch(x, i, 0));
        double* g_ = malloc(n * sizeof(double));
        for (i = 0; i < n; i++) g_[i] = SvNV(*av_fetch(g, i, 0));
        double* diag_ = malloc(n * sizeof(double));
        for (i = 0; i < n; i++) diag_[i] = SvNV(*av_fetch(g, i, 0));
        long iflag_ = SvIV(SvRV(iflag));
        long iprint[2] = { iprt1, iprt2 };
        /* call L-BFGS routine */
        lbfgs_(&n, &m, x_, &f, g_, &diagco, diag_,
	       iprint, &eps, &xtol, (double*)w, &iflag_);
        /* finish */
        av_clear(x);
	av_extend(x, n - 1);
	for (i = 0; i < n; i++)
	   av_store(x, i, newSVnv(x_[i]));
	sv_setiv(SvRV(iflag), iflag_);
        free(x_);
        free(g_);
        free(diag_);
