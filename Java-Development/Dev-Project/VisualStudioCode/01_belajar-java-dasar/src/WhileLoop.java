public class WhileLoop {
    public static void main(String[] args) {
        /*
         - While loop merupakan versi perulangan yang lebih sederhana dibanding for loop
         - Di while loop hanya terdapat kondisi perulangan, tanpa ada init statement dan post statement
         */
        var counter= 1;

        while(counter <=10){ // hanya terdapat kondisi saja
            System.out.println("Perulangan" + counter);
            counter++;
        }
    }

}
