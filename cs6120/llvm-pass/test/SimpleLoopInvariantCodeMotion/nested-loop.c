#include <stdio.h>

int x = 1;

int main() {
  int g_sum = 0;
  for (int j = 0; j < 10; j++) {
    int sum = 0;
    int y = j;
    for (int i = 0; i < 10; i++) {
      // Can be hoisted out of the outer loop.
      int s = x + 5;
      // Can be hoisted out of the inner loop.
      int t = s + y;
      sum += t;
    }
    g_sum += sum;
    printf("%d\n", sum);
  }
  printf("%d\n", g_sum);
  return 0;
}
