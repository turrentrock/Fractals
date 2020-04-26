#include <iostream>
#include <time.h>
#include <iomanip>

#include <cudaErrors.h>
#include <thrust/complex.h>
#include <ImageHelper.h>

__global__ void Julia(unsigned int nx,unsigned int ny,float centerx,float centery,float scale_x,float scale_y,PixelInfo *img){

	int i = threadIdx.x + blockIdx.x * blockDim.x;
	int j = threadIdx.y + blockIdx.y * blockDim.y;

	const int loops = 200;
	const int strength = 100;


	if(i >= nx || j >= ny){
		return;
	}

	float lowx = centerx - scale_x/2;
	float lowy = centery - scale_y/2;

	thrust::complex<float> c = thrust::complex<float>(-1,0);
	thrust::complex<float> z = thrust::complex<float>(lowx+i/float(nx)*scale_x , lowy+j/float(ny)*scale_y);

	float mag;
	for(int l = 0; l < loops ; l++) {

		z = z*z + c;
		mag = norm(z) ;
		if( mag > 4 ) {
			img[j*nx+i].r = int(l/2)%256*strength;
			img[j*nx+i].g = int(l)%256*strength;
			img[j*nx+i].b = int(l/3)%256*strength;
			return;
		}
	}

	img[j*nx+i].r = 256;
	img[j*nx+i].g = 256;
	img[j*nx+i].b = 256;
}


int main() {

	unsigned int nx = 1200;
	unsigned int ny = 600;
	unsigned int tx = 8;
	unsigned int ty = 4;	

	dim3 blocks(nx/tx+1,ny/ty+1);
	dim3 threads(tx,ty);

	// Alloc Img //
	PixelInfo *img;
	checkCudaErrors(cudaMallocManaged((void **)&img,nx*ny*sizeof(PixelInfo)));

	float count = 100;

	float centerx = 0.75-0.125;
	float centery = 0;

	float img_count;
	float reduce;
	for(img_count=0,reduce = 1; reduce < count+1; reduce*=1.2,img_count++ ){
		// Call //
		Julia<<<blocks,threads>>>(nx,ny,centerx,centery,4.0f/reduce,2.0f/reduce,img);
		checkCudaErrors(cudaGetLastError());
		checkCudaErrors(cudaDeviceSynchronize());

		// Save Img //
		std::stringstream ss;
		ss << "./save_folder/Img-" << std::setfill('0') << std::setw(5) << img_count << ".jpg";
		
		saveImage(img,nx,ny,ss.str().c_str());
	}

	// Clean Up //
	checkCudaErrors(cudaFree(img));
	return 0;
}