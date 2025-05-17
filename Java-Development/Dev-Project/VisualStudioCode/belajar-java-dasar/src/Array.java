public class Array {
public static void main(String[] args) {
    // Array diartikan dalam bahasa Indonesia sebagai baris (larik)
    // Array sendiri berisikan kumpulan data dengan tipe yang sama
    // Jumlah data di Array tidak bisa berubah setelah pertama kali dibuat

    // CARA KERJA ARRAY
    // misalkan ingin membuat baris array sebanyak 10, maka cara untuk mengaksesnya
    // ialah dengan mengurangi 1 dari index yang ingin dicari
    // misalnya untuk mengakses 10 maka gunakan [9] 
    
    // format 1 - TipeData[index angka] ...Array;
    String[] stringArray;
    stringArray = new String[3];
    
    stringArray[0] = "Eko";
    stringArray[1] = "Kurniawan";
    stringArray[2] = "Khannedy";
    System.out.println(stringArray[0]);
    System.out.println(stringArray[1]);
    System.out.println(stringArray[2]);

    // Seperti biasa, bahasa pemrogramman java di execute dari atas ke bawah
    // dan bisa mengubah nilai array
    stringArray[0] = "Budi";
    System.out.println(stringArray[0]);

    // Di java tidak ada cara untuk menghapus array
    // yang bisa dilakukan ialah mengubah nilai array menjadi 0 atau null

    
    // OPERASI DI ARRAY
    /*
    array[index] ---> Mengambil data di array
    array[index] = value ---> Mengubah data di array
    array.length ---> mengambil panjang array
    */

    // format 2 - memasukkan kumpulan data array secara langsung (array initializer)
    String[] namaLengkap = {
        "Eko","Kurniawan","Khannedy"
    };
    System.out.println(namaLengkap[0]);
    // Implementasi penghapusan data array | data array tidak bisa dihapus tetapi bisa
    // dikosongkan dengan menggunakan value: 0, null, dan false. 
    namaLengkap [0]= null;
    System.out.println(namaLengkap[0]);


    int[] arrayInt = new int[]{
        1,2,3,4,5,6,7,8,9,10
    };
    //System.out.println(arrayInt[0]);

    long[] arrayLong = {
        10L,20L,30L
    };
    System.out.println(arrayLong.length);
    // Implementasi penghapusan data array | data array tidak bisa dihapus tetapi bisa
    // dikosongkan dengan menggunakan value: 0, null, dan false.
    arrayLong [0]=0;
    System.out.println(arrayLong);

    // format 3 - memasukkan array dalam array
    String[][] members ={
        {"Eko", "Kurniawan", "Khannedy"},
        {"Benny", "Hartanto", "Setiyadi"},
        {"Faris"},
        {"Farid"},
        {"Faris", "Franky", "Fluffy", "Kirk"}
    };
    System.out.println(members[0][1]);
    System.out.println(members[1][0]);
    System.out.println(members[2][0]);
    // Bisa akses dengan variasi dibawah ini
    System.out.println(members[3][0]);
    System.out.println(members[4][3]);
    // Contoh tidak bisa akses
   //System.out.println(members[2][2]);


    // format 4 - menggunakan format 3d dalam array, thanks to @~~Movlution~~~/Mainra
    String[][][] anggota ={ // first 2d layer
    {
        {"Miqdad", "Dad", "Rughby"},
        {"Walles", "Benr", "Sphinx"},
        {"Waldo", "Rocky", "Freyz"},
    },
    {// 2nd 2d layer
        {"Tire", "Sparkplug", "Oil"},
        {"Bumper", "Brakes", "Atang"},
        {"Flank", "Fryd", "Furry"}
    }
};
// Accessing and printing elements
for (int i = 0; i < anggota.length; i++) {
    System.out.println("Layer " + i + ":");
    for (int j = 0; j < anggota[i].length; j++) {
        for (int k = 0; k < anggota[i][j].length; k++) {
            System.out.print(anggota[i][j][k] + " ");
        }
        System.out.println(); // New line after each row
    }
    System.out.println(); // New line between layers
}
}
}

//System.out.println();