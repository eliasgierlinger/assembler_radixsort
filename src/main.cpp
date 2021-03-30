#define len 1000000
#include <stdlib.h>
#include <iostream>
#include <chrono>

extern "C" void RadixSort(unsigned long int* arr, unsigned long int* helperArr, unsigned long int length);

int main() {
	unsigned long int* arr = new unsigned long int[len];
	unsigned long int* helperArr = new unsigned long int[len];

	std::cout << "Allocated Arrays" << std::endl;
	
	for(unsigned long int i = 0; i < len; i++) {
		arr[i] = rand() * (ULONG_MAX/RAND_MAX); //rand returns a value between zero and RAND_MAX. 
	}
	
	std::cout << "Filled with random numbers. Now Starting Sort" << std::endl;

	std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
	RadixSort(arr, helperArr, len);
	std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();

	std::cout << "Finished sorting in " << std::chrono::duration_cast<std::chrono::milliseconds> (end - begin).count() << " milliseconds." << std::endl;

	bool arrErr = false;


	for (unsigned long int i = 0; i < len - 1; i++) {
		if (arr[i] < arr[i + 1]) {
			arrErr = true;
		}
	}


	if (arrErr) {
		std::cout << "The finished array is NOT sorted correctly!" << std::endl;
	}
	else {
		std::cout << "The finished array is sorted correctly!" << std::endl;
	}


	delete[] arr;
	delete[] helperArr;



	return 1;
}

