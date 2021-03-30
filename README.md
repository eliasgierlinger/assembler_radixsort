# Radix Sort in x64 Assembly

This program sorts arrays of unsigned long ints using a radix sort algorithm written in x64 MASM assembly. The bucket count / radix of the sort is 2. For calculating the prefix sum I used 8 AVX 256 bit registers, which can process 8 unsigned long ints at once. Because I am using a radix of 2, I make use of the popcnt instruction, which counts the amounts of 1 bits in a register.

Here are some timings of the algorithm done on an AMD Ryzen 7 2700X - note that the time it takes for the helper array to be allocated is not considered:

<table>
    <tr><th>Array length</th><th>Time in ms</th><tr>
    <tr><td>1000000000</td><td>79100</td><tr>
    <tr><td>750000000</td><td>59979</td><tr>
    <tr><td>500000000</td><td>39483</td><tr>
    <tr><td>250000000</td><td>19688</td><tr>
    <tr><td>----</td><td>----</td><tr>
    <tr><td>100000000</td><td>7940</td><tr>
    <tr><td>75000000</td><td>6019</td><tr>
    <tr><td>50000000</td><td>4055</td><tr>
    <tr><td>25000000</td><td>2031</td><tr>
    <tr><td>----</td><td>----</td><tr>
    <tr><td>10000000</td><td>813</td><tr>
    <tr><td>7500000</td><td>599</td><tr>
    <tr><td>5000000</td><td>419</td><tr>
    <tr><td>2500000</td><td>201</td><tr>
    <tr><td>----</td><td>----</td><tr>
    <tr><td>1000000</td><td>84</td><tr>
    <tr><td>750000</td><td>62</td><tr>
    <tr><td>500000</td><td>45</td><tr>
    <tr><td>250000</td><td>23</td><tr>
    <tr><td>----</td><td>----</td><tr>
    <tr><td>100000</td><td>11</td><tr>
    <tr><td>75000</td><td>8</td><tr>
    <tr><td>50000</td><td>6</td><tr>
    <tr><td>25000</td><td>3</td><tr>
</table>

As can be seen, the timings scale linearly with the array size.

Unfortunately this program performs quite badly when compared to a radix sort with a bucket count of 256. I'd assume, that the thing, which holds this algorithm down, is that the entire array needs to be reordered 32 times. A 256 bucket radix sort only needs to reorder the array 4 times.