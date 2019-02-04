; $Id: ctm_locatediff.pro,v 1.1 2007/07/17 20:41:26 bmy Exp $
;-----------------------------------------------------------------------
;+
; NAME:
;        CTM_SummarizeDIFF
;
; PURPOSE:
;        Locates data blocks which differ in two binary
;        punch files or GMAO met field files.  
;
; CATEGORY:
;        GAMAP Utilities, GAMAP Data Manipulation
;
; CALLING SEQUENCE:
;        CTM_LOCATEDIFF, FILE1, FILE2 [, Keywords ]
;
; INPUTS:
;        FILE1 -> Name of the first file to be tested.  FILE1 may be
;             a binary punch file, and ASCII file, or a GMAO met field
;             file.
;
;        FILE2 -> Name of the second file to be tested.  FILE2 may be
;             a binary punch file, and ASCII file, or a GMAO met field
;             file.
;
; KEYWORD PARAMETERS:
;        DIAGN -> A diagnostic category name to restrict the selection
;             of data records.
;
;        OUTFILENAME -> Name of the output file which will contain
;             the location of differences found between data blocks
;             in FILE1 and FILE2.  If OUTFILENAME is not specified,
;             then CTM_LOCATEDIFF will print this information to
;             the screen.
;
;        /HEADERS_ONLY -> Set this switch to just print the category
;             names and tracer numbers where differences occur instead
;             of printing all of the data points.
;
;        _EXTRA=e -> Picks up any extra keywords for CTM_GET_DATA.
;
; OUTPUTS:
;        None
;
; SUBROUTINES:
;        External subroutines required:
;        ==============================
;        CTM_GET_DATA   UNDEFINE
;        CTM_DIAGINFO
;
; REQUIREMENTS:
;        References routines from both GAMAP and TOOLS directories.
;
; NOTES:
;        (1) Both FILE1 and FILE2 must contain the same diagnostic 
;            categories, listed in the same order.
;
; EXAMPLE:
;        CTM_LOCATEDIFF, 'ctm.bpch.old', 'ctm.bpch.new'
;
;             ; Locates data blocks which differ between ctm.bpch.old
;             ; and ctm.bpch.new.  You can investigate these further
;             ; with routines CTM_PRINTDIFF and CTM_PLOTDIFF.
;
; MODIFICATION HISTORY:
;        bmy, 24 Feb 2003: VERSION 1.00
;        bmy, 19 Nov 2003: GAMAP VERSION 2.01
;                          - Now get spacing between diagnostic
;                            offsets from CTM_DIAGINFO
;        bmy, 27 Feb 2004: GAMAP VERSION 2.02
;                          - Rewritten to also print out locations in
;                            FORTRAN notation where differences occur
;                          - added DIAGN keyword to specify category name
;                          - added OUTFILENAME to specify output file
;  bmy & phs, 13 Jul 2007: GAMAP VERSION 2.10
;        bmy, 01 May 2013: GAMAP VERSION 2.17
;                          - Corrected error in EXAMPLE section above
;  ewl: 20 Sep 2014 : modified by L. Lundgren
;-
; Copyright (C) 2003-2007,
; Bob Yantosca and Philippe Le Sager, Harvard University
; This software is provided as is without any warranty whatsoever. 
; It may be freely used, copied or distributed for non-commercial 
; purposes. This copyright notice must be kept with any copy of 
; this software. If this software shall be used commercially or 
; sold as part of a larger package, please contact the author.
; Bugs and comments should be directed to bmy@io.as.harvard.edu
; or phs@io.harvard.edu with subject "IDL routine ctm_locatediff"
;-----------------------------------------------------------------------


pro CTM_SummarizeDiff, File1, File2,                                        $
                    DiagN=DiagN,                OutFileName=OutFileName, $
                    Headers_Only=Headers_Only,  _EXTRA=e

   ;====================================================================
   ; Initialization
   ;====================================================================

   ; External Functions
   FORWARD_FUNCTION Convert_Index

   ; Keywords
   Headers_Only = Keyword_Set( Headers_Only )
   if ( N_Elements( File1 ) ne 1 ) then Message, 'Must pass FILE1!'
   if ( N_Elements( File2 ) ne 1 ) then Message, 'Must pass FILE2'

   ; Write to file?
   Do_Write = ( N_Elements( OutFileName ) eq 1 )
   
   ; Print data & differences to screen? 
   Do_Print = 1L - Headers_Only

   ;====================================================================
   ; Read data 
   ;====================================================================
 
   ; Read data from old & new files (use cat name if passed)
   if ( N_Elements( DiagN ) gt 0 ) then begin
      CTM_Get_Data, DInfo_Old, DiagN, File=File1, /Quiet, _EXTRA=e
      CTM_Get_Data, DInfo_New, DiagN, File=File2, /Quiet, _EXTRA=e
   endif else begin
      CTM_Get_Data, DInfo_Old,        File=File1, /Quiet, _EXTRA=e
      CTM_Get_Data, DInfo_New,        File=File2, /Quiet, _EXTRA=e
   endelse

   ; Get number of data blocks in old & new files
   N_Old = N_Elements( DInfo_Old )
   N_New = N_Elements( DInfo_New )
 
   ; Make sure old & new files have same # of data blocks
   ; (this is the cheap test for identical diagnostics!)
   if ( N_Old ne N_New ) then begin
      Message, 'FILE1 and FILE2 do not contain compatible diagnostics!'
   endif
    
   ; Get diagnostic spacing (same for all category names)
   CTM_DiagInfo, DInfo_Old[0].Category, Spacing=Spacing
   Spacing = Spacing[0]

   ;====================================================================
   ; Loop over corresponding data blocks in both files
   ;====================================================================

   ; Format string for use below
   S0 = '(''maxDecr%='', e14.7, '',  maxIncr%='', e14.7, '',  maxAbsDiff='', e14.7)'

   ; If OUTFILENAME is specified, then open file for output 
   if ( Do_Write ) then Open_File, OutFileName, Ilun, /Get_LUN, /Write
      
   ; Loop over data blocks
   for D = 0L, N_Old-1L do begin
 
      ;-------------------------------
      ; Test for differences
      ;-------------------------------

      ; Get data blocks from old & new files
      Data_Old  = *( DInfo_Old[D].Data )
      Data_New  = *( DInfo_New[D].Data )
 
      ; Sum the differences between the two arrays.  
      ; DATA_DIFF will equal zero if both arrays are identical
      Data_Diff = Data_New - Data_Old

      ; Index of points which have differences
      IndDiff   = Where( Abs( Data_Diff ) gt 0.0 )

      ;--------------------------------
      ; Print header info for diff's
      ;--------------------------------
      if ( IndDiff[0] ge 0 ) then begin
         
         ; GAMAP tracer number
         Tracer = DInfo_Old[D].Tracer mod Spacing
         Unit   = StrTrim( DInfo_Old[D].Unit, 2 )

         ; Format string with cat name, tracer, TAU
         S = 'Diff in '   + String( DInfo_Old[D].Category, Format='(a8)'    )+$
           ' ['  + StrTrim( DInfo_Old[D].Unit, 2 ) + ']'                     +$
           ' for tracer ' + String( Tracer,                Format='(i4)'    )+$
           ' at TAU = '   + String( DInfo_Old[D].Tau0,     Format='(f13.3)' )

         ; Write headers
         if ( Do_Write ) then begin

            ; Write to file
            if ( Do_Print ) then PrintF, Ilun
            PrintF, Ilun, S 

         endif else begin

            ; Write to screen
            if ( Do_Print ) then Print
            Print, S 
            if ( Do_Print ) then Pause
               
         endelse

         ;--------------------------------
         ; Print min and max percent diff
         ;--------------------------------
         maxIncr =  0.0
         maxDecr =  -1.0e-30
         maxDiff =  0.0
         if ( Do_Print ) then begin

            ; Loop over elements which differ
            for N = 0L, N_Elements( IndDiff )-1L do begin

               ; Convert 3-D indices to 1-D indices
               Coords = Convert_Index( IndDiff[N], DInfo_Old[D].Dim[0:2] ) + 1L

               ; Difference, old data, new data
               Diff   = Data_Diff[ IndDiff[N] ]
               D1     = Data_Old[ IndDiff[N] ]
               D2     = Data_New[ IndDiff[N] ]

               ; ewl: percent difference 100 * (new - old) / old
               Perc   =  100 *  (D2 - D1) / D1

               ; ewl: value of largest difference (increase or decrease)
               if ( ABS( Diff ) gt maxDiff ) then begin
                  maxDiff =  Diff 
               endif

               ; Update min and max percent difference
               if ( Perc gt 0 and Perc gt maxIncr ) then begin
                  maxIncr =  Perc
               endif
               if ( Perc lt 0 and Perc lt maxDecr ) then begin
                  maxDecr =  Perc
               endif

               ; Write location and difference to output file or screen
;               if ( Do_Write )                                       $
;                  then PrintF, Ilun, Coords, D2, D1, Diff, Format=S0 $
;                  else Print,        Coords, D2, D1, Diff, Format=S0

            endfor

            ; Get total number of elements differing
            numDiff =  N_Elements( IndDiff )

            ; Write summary
            if ( Do_Write )                                        $
               then PrintF, Ilun, numDiff, ' differences:'$
               else Print,        numDiff, ' differences:'

            if ( Do_Write )                                       $
               then PrintF, Ilun, maxDecr, maxIncr, maxDiff, Format=S0 $
               else Print,        maxDecr, maxIncr, maxDiff, Format=S0

            ; Stop for examination (if not writing to file)
            if ( not Do_Write ) then Pause
         endif
      endif
 
      ; Undefine stuff
      UnDefine, IndDiff
      UnDefine, Data_Old
      UnDefine, Data_New
      UnDefine, Data_Diff
   endfor

   ;====================================================================
   ; Cleanup and quit
   ;====================================================================
   if ( Do_Write ) then begin
      Close,    Ilun
      Free_LUN, Ilun
   endif

end
