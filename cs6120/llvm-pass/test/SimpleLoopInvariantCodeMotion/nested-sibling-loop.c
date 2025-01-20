#include <stdio.h>

int x = 1;

int main() {
  int g_sum = 0;
  for (int j = 0; j < 10; j++) {
    /*
     *
     */
    int sum_1 = 0;
    int y = j;
    for (int i = 0; i < 10; i++) {
      // Can be hoisted out of the outer loop.
      int s = x + 5;
      // Can be hoisted out of the inner loop.
      int t = s + y;
      sum_1 += t;
    }
    printf("%d\n", sum_1);
    g_sum += sum_1;

    /*
     *
     */
    int sum_2 = 0;
    int z = j + 1;
    for (int i = 0; i < 20; i++) {
      // Can be hoisted out of the outer loop.
      int s = x + 6;
      // Can be hoisted out of the inner loop.
      int t = s + z;
      sum_2 += t;
    }
    printf("%d\n", sum_2);
    g_sum += sum_2;
  }
  printf("%d\n", g_sum);

  return 0;
}
