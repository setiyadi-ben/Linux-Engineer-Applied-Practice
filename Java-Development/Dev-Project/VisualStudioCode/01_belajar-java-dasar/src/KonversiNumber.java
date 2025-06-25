public class KonversiNumber {
    public static void main(String[] args) {
        // Konversi Tipe Data Number
    
        // Widening Casting (Otomatis): byte->short->int->float->double
        byte iniByte= 10;
        short iniShort= iniByte; //bisa langsung dikonversi hasilnya

        
        // Narrowing Casting (Manual): double ->float->long->int->char->short->byte
        int iniInt2 = 1000;
        byte iniByte2 = (byte) iniInt2; // Konversi macam ini akan menimbulkan number overflow
        // Sederhananya jika nilai int iniInt2 = 1000; mK nilai byte akan mulai dari 0 hingga 127
        // terus berkurang sampai minus -128 dan akan terus berulang sampai nilai 100 terpenuhi

    }

}
