# performance.quantize_linear

```rust
fn quantize_linear(self: @Tensor<T>) -> Tensor<T>;
```

Quantizes a Tensor using symmetric quantization.

This is an 8-bit linear quantization of a tensor. This method allows tensors to be stored at lower bitwidths than those of fixed-point precision.

During quantization, the unquantized values are mapped to an 8 bit quantization space of the form:

`quantized_value = value / scale`

`scale` is a positive number used to map the unquantized numbers to a quantization space. It is calculated as follows in symmetric quantization:

```
scale = max(abs(data_range_max), abs(data_range_min)) * 2 / (quantization_range_max - quantization_range_min)
```

## Args

* `tensor`(`@Tensor<T>`) - The input tensor.

## Returns

A new `Tensor<T>` with the same shape as the input tensor, containing the quantized values.

## Examples

```rust
use orion::performance::core::PerfomanceTrait;
use orion::performance::implementations::impl_performance_i32;

fn quantize_linear_example() -> Tensor<i32> {
// We instantiate a 2D Tensor here.
// [[-30523, 24327, -12288],[29837, -19345, 15416]]
let tensor = i32_tensor_3x2_helper();

// We can call `quantize_linear` function as follows.
return PerfomanceTrait::quantize_linear(@tensor);
}
>>> [[-127, 101, -51],[124, -80, 64]]
```
