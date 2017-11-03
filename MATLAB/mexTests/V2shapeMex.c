#include "mex.h"
#include <string.h>
#include <math.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Input variables
    #define V_in	prhs[0]
    #define F_in	prhs[1]
    
    double *V;
    double *F;
    
    int numVertices, d, n, numFaces;
    if (nrhs == 2)
    {
        V = mxGetPr(V_in);
        F = mxGetPr(F_in);
        numVertices = mxGetDimensions(V_in)[0]; // Number of vertices
        d = mxGetDimensions(V_in)[1]; // dimension
        n = mxGetDimensions(F_in)[0]; // Vertices per face
        numFaces = mxGetDimensions(F_in)[1]; // Number of faces
    }
    
    // set up struct
    const char **fieldnames;
    fieldnames = mxCalloc(6, sizeof(*fieldnames));
    
    fieldnames[0] = "XData";
    fieldnames[1] = "YData";
    fieldnames[2] = "ZData";
    fieldnames[3] = "V";
    fieldnames[4] = "min";
    fieldnames[5] = "max";
    
    plhs[0] = mxCreateStructMatrix(1,1,6,fieldnames);
    
    // XData, YData, ZData
    mxArray *XData_out = mxCreateDoubleMatrix(n, numFaces, mxREAL);
    mxArray *YData_out = mxCreateDoubleMatrix(n, numFaces, mxREAL);
    mxArray *ZData_out = mxCreateDoubleMatrix(n, numFaces, mxREAL);

    double *XData_pr = mxGetPr(XData_out);
    double *YData_pr = mxGetPr(YData_out);
    double *ZData_pr = mxGetPr(ZData_out);
    
    int i, j;
    for (i = 0; i<n; ++i)
        for (j = 0; j<numFaces; ++j)
        {
            XData_pr[i+j*n] = V[(int)F[i+j*n]-1];
            YData_pr[i+j*n] = V[numVertices + (int)F[i+j*n]-1];
            ZData_pr[i+j*n] = V[2*numVertices + (int)F[i+j*n]-1];
        }
    
    mxSetFieldByNumber(plhs[0],0,0,XData_out);
    mxSetFieldByNumber(plhs[0],0,1,YData_out);
    mxSetFieldByNumber(plhs[0],0,2,ZData_out);
    
    // V
    mxArray *V_out = mxCreateDoubleMatrix(numVertices, d, mxREAL);
    memcpy(mxGetPr(V_out), V, sizeof(double)*numVertices*d);
    mxSetFieldByNumber(plhs[0],0,3,V_out);
    
    // min max
    mxArray *min_out = mxCreateDoubleMatrix(1, d, mxREAL);
    mxArray *max_out = mxCreateDoubleMatrix(1, d, mxREAL);
    
    double *min_pr = mxGetPr(min_out);
    double *max_pr = mxGetPr(max_out);
    
    for (i = 0; i<d; ++i)
        min_pr[i] = max_pr[i] = V[i*numVertices];
    
    for (i = 1; i<numVertices; ++i)
        for (j = 0; j<d; ++j)
        {
            min_pr[j] = V[i + j*numVertices] < min_pr[j] ? V[i + j*numVertices] : min_pr[j];
            max_pr[j] = V[i + j*numVertices] > max_pr[j] ? V[i + j*numVertices] : max_pr[j];
        }
    mxSetFieldByNumber(plhs[0],0,4,min_out);
    mxSetFieldByNumber(plhs[0],0,5,max_out);
    return;
}