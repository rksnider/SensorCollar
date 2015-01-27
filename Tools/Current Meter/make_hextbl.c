// ***************************************************************************
//
//  Make a hexadecimal text table.
//  Make a lookup table that gives the hexadecimal value of each position in
//  the table.  There are characters for each byte.
//
//  @file       $File$
//  @author     Emery Newlon
//  @version    $Revision$
//
// ***************************************************************************
//

#include <stdio.h>
#include <stdlib.h>


// ***************************************************************************
//
//  Build the table.
//  Build a hex text lookup table.
//
//  @return             0 if successful, 1 on error.
//
// ***************************************************************************
//

void main ()
{
    int         i ;
    char    *   prefix ;
    FILE    *   table_file ;

    //  Open the translation table.

    if ((table_file = fopen ("hex_byte_tbl.c", "w")) == NULL)
    {
        fprintf (stderr, "Unable to create table file\n") ;
        exit (1) ;
    }

    //  Create the table.

    fprintf (table_file,
        "// *****************************************************************\n"
        "//\n"
        "//  Hexadecimal text lookup table definition.\n"
        "//  This table contains the hexadecimal text for index used to\n"
        "//  lookup that entry.  A CR/LF is appended to the end.\n"
        "//\n"
        "//  @file       $File$\n"
        "//  @version    $Revision$\n"
        "//\n"
        "// *****************************************************************\n"
        "//\n\n"
        "#include <stdint.h>\n\n"
        "const uint16_t  hex_byte_tbl [] =\n{\n") ;

    prefix = "    " ;

    for (i = 0 ; i < 256 ; i ++)
    {
        fprintf (table_file, "%s0x%04X", prefix,
                 "0123456789ABCDEF" [i / 16] +
                 "0123456789ABCDEF" [i % 16] * 256) ;

        if (i % 8 == 7)
        {
            prefix = ",\n    " ;
        }
        else
        {
            prefix = ", " ;
        }
    }

    //  Add a CR/LF to the end of the table.

    fprintf (table_file, "%s0x%04X\n} ;\n\n", prefix, '\r' + '\n' * 256) ;

    fclose (table_file) ;
    exit   (0) ;

}   //  END main
