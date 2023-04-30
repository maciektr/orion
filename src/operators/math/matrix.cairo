use array::ArrayTrait;
use box::BoxTrait;
use option::OptionTrait;

use onnx_cairo::operators::math::signed_integer::IntegerTrait;
use onnx_cairo::operators::math::signed_integer::i32;
use onnx_cairo::utils::check_gas;

#[derive(Drop)]
struct Matrix {
    rows: usize,
    cols: usize,
    data: Array::<i32>,
}

trait MatrixTrait {
    fn new(rows: usize, cols: usize, data: Array::<i32>) -> Matrix;
    fn get(self: @Matrix, i: usize, j: usize) -> i32;
    fn dot(self: @Matrix, other: @Matrix) -> Matrix;
    fn add(self: @Matrix, other: @Matrix) -> Matrix;
    fn len(self: @Matrix) -> usize;
    fn argmax(self: @Matrix) -> Array::<usize>;
    fn reduce_sum(self: @Matrix) -> i32;
}

impl MatrixImpl of MatrixTrait {
    fn new(rows: usize, cols: usize, data: Array::<i32>) -> Matrix {
        assert(data.len() == rows * cols, 'Matrix not match dimensions');
        matrix_new(rows, cols, data)
    }

    /// Gets the value of a particular element in the matrix.
    ///
    /// # Arguments
    ///
    /// * `self` - A reference to the matrix.
    /// * `i` - The row index of the element.
    /// * `j` - The column index of the element.
    ///
    /// # Returns
    ///
    /// The value of the element at the specified row and column.
    ///
    /// # Panics
    ///
    /// Panics if the row index or column index is out of bounds.
    fn get(self: @Matrix, i: usize, j: usize) -> i32 {
        assert(i < *self.rows, 'row out of bounds');
        assert(j < *self.cols, 'column out of bounds');

        *self.data.at(i * *self.cols + j)
    }

    /// Computes the matrix dot product of this matrix and another matrix.
    ///
    /// # Arguments
    ///
    /// * `self` - A reference to the left-hand matrix.
    /// * `other` - A reference to the right-hand matrix.
    ///
    /// # Returns
    ///
    /// A new matrix that is the matrix dot product of this matrix and the other matrix.
    ///
    /// # Panics
    ///
    /// Panics if the number of columns in the left-hand matrix does not match the number of rows in the right-hand matrix.
    fn dot(self: @Matrix, other: @Matrix) -> Matrix {
        let mut arr = ArrayTrait::<i32>::new();

        let mut row_index: usize = 0;
        loop {
            check_gas();

            // Compute dot product of the row
            let dot = _row_dot_vec(self, ref arr, other, row_index, 0_usize);

            arr.append(dot);

            row_index += 1;
            if row_index == *self.rows {
                break ();
            };
        };

        MatrixTrait::new(*self.rows, *other.cols, arr)
    }

    /// Adds another matrix to this matrix element-wise.
    ///
    /// # Arguments
    ///
    /// * `self` - A reference to the matrix.
    /// * `other` - A reference to the matrix to be added.
    ///
    /// # Returns
    ///
    /// A new matrix that is the element-wise sum of this matrix and the other matrix.
    ///
    /// # Panics
    ///
    /// Panics if the input matrices have different dimensions.
    fn add(self: @Matrix, other: @Matrix) -> Matrix {
        assert(*self.rows == *other.rows, 'Matrix not match dimensions');
        assert(*self.cols == *other.cols, 'Matrix not match dimensions');

        let mut arr = ArrayTrait::<i32>::new();

        let mut row_index: usize = 0;
        loop {
            check_gas();

            _row_add_vec(self, ref arr, other, row_index, 0);

            row_index += 1;
            if row_index == *self.rows {
                break ();
            };
        };

        MatrixTrait::new(*self.rows, *self.cols, arr)
    }

    /// Returns the number of elements in the matrix.
    ///
    /// # Arguments
    ///
    /// * `self` - A reference to the matrix.
    ///
    /// # Returns
    ///
    /// The number of elements in the matrix.
    fn len(self: @Matrix) -> usize {
        self.data.len()
    }

    /// Returns an array of the indices of the maximum values in the matrix along axis 0.
    ///
    /// # Arguments
    ///
    /// * `self` - A reference to the matrix.
    ///
    /// # Returns
    ///
    /// An array of the indices of the maximum values in the matrix along axis 0.
    fn argmax(self: @Matrix) -> Array::<usize> {
        let mut arr = ArrayTrait::<usize>::new();

        let mut row_index: usize = 0;
        loop {
            check_gas();

            // Compute dot product of the row
            _row_argmax_vec(self, ref arr, 0, IntegerTrait::new(0, false), row_index, 0);

            row_index += 1;
            if row_index == *self.rows {
                break ();
            };
        };

        arr
    }

    /// Computes the sum of all elements in the matrix.
    fn reduce_sum(self: @Matrix) -> i32 {
        let mut sum = IntegerTrait::new(0_u32, false);

        let mut row_index: usize = 0;
        loop {
            check_gas();

            _row_reduce_sum_inner(self, ref sum, row_index, 0);

            row_index += 1;
            if row_index == *self.rows {
                break ();
            };
        };

        sum
    }
}

fn matrix_new(rows: usize, cols: usize, data: Array::<i32>) -> Matrix {
    Matrix { rows: rows, cols: cols, data: data,  }
}

// **********************
// * Matrix DOT product *
// **********************

fn _row_dot_vec(
    self: @Matrix, ref arr: Array::<i32>, other: @Matrix, row_index: usize, col_index: usize
) -> i32 {
    check_gas();

    // End of the recursion
    if (col_index == *self.cols) {
        return IntegerTrait::new(0_u32, false);
    }

    let mut ele = IntegerTrait::new(0_u32, false);
    // Calculates the product
    match self.data.get(*self.cols * row_index + col_index) {
        Option::Some(x) => {
            ele = *x.unbox();
        },
        Option::None(_) => {
            let mut data = ArrayTrait::new();
            data.append('out of bounds');
            panic(data)
        }
    }

    let mut other_ele = IntegerTrait::new(0_u32, false);
    match other.data.get(col_index) {
        Option::Some(x) => {
            other_ele = *x.unbox();
        },
        Option::None(_) => {
            let mut data = ArrayTrait::new();
            data.append('out of bounds');
            panic(data)
        }
    }
    let result = ele * other_ele;
    let acc = _row_dot_vec(self, ref arr, other, row_index, col_index + 1_usize);

    // Returns the sum of the current product with the previous ones
    return acc + result;
}

// **************
// * Matrix ADD *
// **************

fn _row_add_vec(
    self: @Matrix, ref arr: Array::<i32>, other: @Matrix, row_index: usize, col_index: usize
) {
    check_gas();

    // End of the recursion
    if (col_index == *self.cols) {
        return ();
    }

    let mut ele = IntegerTrait::new(0_u32, false);
    // Calculates the product
    match self.data.get(*self.cols * row_index + col_index) {
        Option::Some(x) => {
            ele = *x.unbox();
        },
        Option::None(_) => {
            let mut data = ArrayTrait::new();
            data.append('out of bounds');
            panic(data)
        }
    }

    let mut other_ele = IntegerTrait::new(0_u32, false);
    match other.data.get(*other.cols * row_index + col_index) {
        Option::Some(x) => {
            other_ele = *x.unbox();
        },
        Option::None(_) => {
            let mut data = ArrayTrait::new();
            data.append('out of bounds');
            panic(data)
        }
    }
    arr.append(ele + other_ele);
    _row_add_vec(self, ref arr, other, row_index, col_index + 1_usize);
}


// *****************
// * Matrix ARGMAX *
// *****************

fn _row_argmax_vec(
    self: @Matrix,
    ref arr: Array::<usize>,
    max_index: usize,
    max_value: i32,
    row_index: usize,
    col_index: usize
) {
    check_gas();

    // End of the recursion
    if (col_index == *self.cols) {
        arr.append(max_index);
        return ();
    }

    let current_value = self.get(row_index, col_index);
    if current_value > max_value {
        _row_argmax_vec(self, ref arr, col_index, current_value, row_index, col_index + 1_usize);
    } else {
        _row_argmax_vec(self, ref arr, max_index, max_value, row_index, col_index + 1_usize);
    }
}


// *********************
// * Matrix REDUCE_SUM *
// *********************

fn _row_reduce_sum_inner(self: @Matrix, ref sum: i32, row_index: usize, col_index: usize) {
    check_gas();

    // End of the recursion
    if (col_index == *self.cols) {
        return ();
    }

    let current_value = self.get(row_index, col_index);
    sum = sum + current_value;

    _row_reduce_sum_inner(self, ref sum, row_index, col_index + 1_usize);
}
