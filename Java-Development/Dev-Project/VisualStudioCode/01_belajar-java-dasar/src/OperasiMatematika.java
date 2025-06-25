public class OperasiMatematika {
    public static void main(String[] args) {
        int a = 100;
        int b = 10;

        // Run untuk mengetahui outputnya
        System.out.println(a+b);
        System.out.println(a-b);
        System.out.println(a*b);
        System.out.println(a/b);
        // Modulo adalah hasil sisa dari pembagian 
        System.out.println(a%b);

    // Contoh augmented assigments
    /*
     a = a+10 || a += 10
     a = a-10 || a -= 10
     a = a*10 || a *= 10
     a = a/10 || a /= 10
     a = a%10 || a %= 10
    */
    int c = 200;

    c += 10;
    System.out.println(c);

    c -= 10;
    System.out.println(c);

    c *= 10;
    System.out.println(c);

    c /= 10;
    System.out.println(c);

    c %= 10;
    System.out.println(c);

    // contoh Unary Operator
    /*
     ++ || a = a+1
     -- || a = a-1
     -  || negatif
     +  || positif
     !  || boolean bernilai kebalikan (tidak sama dengan)
     */
    int d = 300;
    // int positif = +100;
    // int negatif = -10;

    d++;
    System.out.println(d);

    d--;
    System.out.println(d);

    System.out.println(!true);

    }
}
