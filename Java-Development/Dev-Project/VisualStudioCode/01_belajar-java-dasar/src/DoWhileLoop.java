public class DoWhileLoop {
public static void main(String[] args) {
    /*
     - DO while loop adlah kondisi perulangan yang mirip while
     - Perbedaannya hanya pada pengecekan kondisi, maksudnya:
     Pengecekan kondisi while loop dilakukan di awal sebelum perulangan dilakukan sedangkan,
     do while loop dilakukan setelah perualangan dilakukan.

    Jadi, di do while loop, minimal pasti 1x perulangan dilakukan walaupun kondisi tidak bernilai true.
     */
    var counter = 100;
    do{
        System.out.println("Perulangan " + counter);
        counter++;
    } while (counter <=10);
}
}
