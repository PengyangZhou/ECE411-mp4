/*  This interface contains the ports encapsulated in a CDB.
    This is for convenient refraction of CDB signals.
 */

interface cdb_itf;
    logic [4:0]  ROB_idx;
    logic [31:0] value;

endinterface : cdb_itf
