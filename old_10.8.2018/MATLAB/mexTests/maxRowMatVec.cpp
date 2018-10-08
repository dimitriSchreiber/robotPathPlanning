#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Input variables
    #define A_in               prhs[0]
    #define v_in               prhs[1]
    
    double *A;
    double *v;
    
    A = mxGetPr(A_in);
    int N = mxGetDimensions(A_in)[0];     // Number of samples
    int d = mxGetDimensions(v_in)[0]; // Get number of dim
    
    double maxVal = -1000000., maxValTemp;
    int argmax = 0;
    
    v = mxGetPr(v_in);
    for (int j = 0; j < N; ++j)
    {
        maxValTemp = 0;
        for (int i = 0; i < d; ++i)
            maxValTemp += A[j+i*N]*v[i];
        
        if (maxValTemp > maxVal)
        {
            maxVal = maxValTemp;
            argmax = j;
        }
    }
    plhs[0] = mxCreateDoubleMatrix(1, d, mxREAL);
    for (int i = 0; i < d; ++i)
        mxGetPr(plhs[0])[i] = A[argmax+i*N];
    
    return;
}