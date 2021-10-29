/*  This interface contains the ports encapsulated in a CDB.
    This is for convenient refraction of CDB signals.
 */

interface cdb_itf;
    bit             busy;
    logic [4:0]     tag;
    logic [31:0]    val;

endinterface : cdb_itf
