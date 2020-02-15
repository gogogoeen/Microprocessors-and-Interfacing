#include <stdio.h>
#include <stdlib.h>

/* run this program using the console pauser or add your own getch, system("pause") or input loop */


int gcd(int a, int b){
	if (b!=0){
		return gcd(b,a%b);
	}else {
		return a;
	}
}


int main(int argc, char *argv[]) {
	int a=36;
	int b=84;
	int c;
	c=gcd(a,b);
	printf("%d",c);
	return 0;
	
}

