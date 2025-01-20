#include <stdio.h>

int x = 1;

int main() {
  int sum = 0;
  for (int i = 0; i < 10; i++) {
    // Can be moved outside the loop.
    int s = x + 5;
    sum += s;
  }
  printf("%d\n", sum);
  return 0;
}
