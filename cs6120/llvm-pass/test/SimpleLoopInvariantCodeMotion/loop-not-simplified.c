#include <stdio.h>

int main() {
  int i = 10;
  while (i--) {
    printf("%d\n", i);
    if (i == 5) {
      // Extra latch.
      break;
    }
  }
  return 0;
}
