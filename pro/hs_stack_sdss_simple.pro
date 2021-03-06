pro hs_stack_sdss_simple, list_file, $
    suffix=suffix, sample=sample, $
    hvdisp_home=hvdisp_home, data_dir=data_dir, dust_dir=dust_dir, $ 
    create=create, post=post, avg_boot=avg_boot, $
    csigma=csigma, n_boot=n_boot, sig_cut=sig_cut, $
    blue_cut=blue_cut, red_cut=red_cut, niter=niter, nevec=nevec, $ 
    test_str=test_str, new_prep=new_prep, $ 
    sky_factor=sky_factor, f_cushion=f_cushion, $
    min_wave_hard=min_wave_hard, max_wave_hard=max_wave_hard

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Parameters   
    if keyword_set( csigma ) then begin 
        csigma = float( csigma ) 
    endif else begin 
        csigma = 350.0
    endelse
    ;; For Bootstrap run
    if keyword_set( n_boot ) then begin 
        n_boot = long( n_boot ) 
    endif else begin 
        n_boot  = 500
    endelse
    if keyword_set( sig_cut ) then begin 
        sig_cut = float( sig_cut ) 
    endif else begin 
        sig_cut = 3.5
    endelse
    ;; For VWPCA run
    if keyword_set( blue_cut ) then begin 
        blue_cut = float( blue_cut ) 
    endif else begin 
        blue_cut = 160.0 
    endelse
    if keyword_set( red_cut ) then begin 
        red_cut = float( red_cut ) 
    endif else begin 
        red_cut  = 160.0 
    endelse
    if keyword_set( niter ) then begin 
        niter = long( niter ) 
    endif else begin 
        niter    = 5 
    endelse
    if keyword_set( nevec ) then begin 
        nevec = long( nevec ) 
    endif else begin 
        nevec    = 6
    endelse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Factor to reject pixels that are affected by sky emission lines 
    if keyword_set( sky_factor ) then begin 
        sky_factor = float( sky_factor )
    endif else begin 
        sky_factor = 2.0
    endelse
    ;; Cushion factor: define the wavelength range you want to hide at both 
    ;;   short and long wavelength end; The smaller the value of this 
    ;;   factor, the more you hide.  Normally 2.0-5.0 should be fine
    if keyword_set( f_cushion ) then begin 
        f_cushion = float( f_cushion )
    endif else begin 
        f_cushion = 4.0 
    endelse
    ;; Hard-coded wavelength limits for Robust-PCA method
    if keyword_set( min_wave_hard ) then begin 
        min_wave_hard = float( min_wave_hard )
    endif else begin 
        min_wave_hard = 3600.0 
    endelse
    if keyword_set( max_wave_hard ) then begin 
        max_wave_hard = float( max_wave_hard )
    endif else begin 
        max_wave_hard = 8580.0 
    endelse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if NOT keyword_set( hvdisp_home ) then begin 
        hvdisp_location, hvdisp_home, data_home
    endif else begin 
        hvdisp_home = strcompress( hvdisp_home, /remove_all ) 
    endelse
    len_1 = strlen(hvdisp_home)
    if strmid( hvdisp_home, ( len_1 - 1 ), len_1 ) NE '/' then begin 
        hvdisp_home = hvdisp_home + '/'
    endif 

    if NOT keyword_set( data_dir ) then begin 
        data_home = './'
    endif else begin 
        data_home = strcompress( data_dir, /remove_all )
    endelse
    len_2 = strlen(data_home)
    if strmid( data_home, ( len_2 - 1 ), len_2 ) NE '/' then begin 
        data_home = data_home + '/'
    endif 

    if NOT keyword_set( sample ) then begin 
        sample = 'coadd'
    endif else begin 
        sample = strcompress( sample, /remove_all )
    endelse

    if keyword_set( suffix ) then begin 
        suffix = strcompress( suffix, /remove_all )
    endif else begin 
        suffix = 'hs'
    endelse

    if keyword_set( dust_dir ) then begin 
        ipath = strcompress( dust_dir, /remove_all )
    endif else begin 
        ;; Where one can find the 'SFD_dust_4096_ngp[sgp].fits' files
        ipath = '/Users/songhuang/work/data/dust_data/' 
    endelse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if NOT file_test( list_file ) then begin 
        print, '###############################################################'
        print, ' Can not find the list of spectra : ' + list_file + ' !!'
        print, '###############################################################'
        message, ' '
    endif else begin 
        readcol, list_file, list_spec, format='A', delimiter=',', comment='#', $
            /silent, count=n_spec  
        list_spec  = strcompress( list_spec,  /remove_all ) 
    endelse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Prepare individual spectrum
    for ii = 0L, ( n_spec - 1 ), 1 do begin 

        spec_file = data_home + list_spec[ ii ]
        spec_prep = spec_file 
        strreplace, spec_prep, '.fits', '_' + suffix + '.fits'
        if (NOT file_test( spec_prep)) OR keyword_set( new_prep ) then begin 
            ;; In case you don't want to use Galactic extinction correction 
            ;;   change /ccm to /no_extcorr
            hs_sdss_prep_spec, spec_file, /quiet, /no_extcorr, /save_sl, $
                suffix=suffix, ipath=ipath
        endif 
    endfor 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Prepare the coadd 
    prep_file = data_home + sample + '_prep.fits' 

    if (NOT file_test( prep_file )) OR keyword_set( new_prep ) then begin 
        hs_coadd_sdss_prep, list_file, $
            hvdisp_home=hvdisp_home, data_home=data_home, $
            csigma=csigma, output=prep_file, suffix=suffix, $
            /mask_all, /quiet, sky_factor=sky_factor, f_cushion=f_cushion 
    endif
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Robust Coadd 
    robust_output = data_home + sample + '_robust.fits'
    robust_prefix = data_home + sample + '_robust'

    robust_coadd = hs_coadd_sdss_robust( prep_file, /plot, $
        /save_fits, blue_cut=blue_cut, red_cut=red_cut, $
        min_wave_hard=min_wave_hard, max_wave_hard=max_wave_hard, $
        niter=niter, nevec=nevec, hvdisp_home=hvdisp_home, $
        data_home=data_home, /noprefix_dir)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Median Coadd
    median_output = data_home + sample + '_median.fits'
    median_prefix = data_home + sample + '_median'

    median_coadd = hs_coadd_sdss_median( prep_file, /plot, $
        /save_fits, n_boot=n_boot, /save_all, $
        hvdisp_home=hvdisp_home, data_dir=data_home, $
        sig_cut=sig_cut, /noprefix_dir ) 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Put the results in an IDL SAV file
    sav_file = data_home + sample + '_coadd.sav' 

    save, /variables, filename=sav_file
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Post Reduction
    ;; Read in the preparation file 
    prep_struc = mrdfits( prep_file, 1, status=status, /silent )
    if ( status NE 0 ) then begin 
        print, ' Something wrong with the preparation file !!'
        message, ' ' 
    endif 

    ;; Necessary information from the _prep file
    sig_convol = csigma 
    n_spec     = prep_struc.n_spec
    min_rest   = prep_struc.min_rest
    max_rest   = prep_struc.max_rest
    min_norm   = prep_struc.min_norm
    max_norm   = prep_struc.max_norm
    prep_lquar = prep_struc.lquar 
    prep_uquar = prep_struc.uquar 
    prep_lifen = prep_struc.lifen
    prep_uifen = prep_struc.uifen
    prep_lofen = prep_struc.lofen
    prep_uofen = prep_struc.uofen
    prep_frac  = prep_struc.frac
    prep_s2nr  = prep_struc.final_snr

    ;; Useful information from Median_Coadd 
    n_pix_median = n_elements( median_coadd.wave )
    median_wave  = median_coadd.wave 
    if keyword_set( avg_boot ) then begin 
        median_arr = median_coadd.avg_boot 
    endif else begin 
        median_arr = median_coadd.med_boot
    endelse
    median_med   = median_coadd.med_boot 
    median_avg   = median_coadd.avg_boot 
    median_sig   = median_coadd.sig_boot
    median_min   = median_coadd.min_boot
    median_max   = median_coadd.max_boot
    median_mask  = median_coadd.final_mask

    ;; Useful information from Robust_Coadd 
    n_pix_robust = n_elements( robust_coadd.new_wave ) 
    robust_wave  = robust_coadd.new_wave 
    robust_arr   = robust_coadd.mean_flux 

    ;; Interpolate the robust mean spectrum back to original wave array 
    index_blu = where( median_wave LE min( robust_wave ), n_blu )
    index_red = where( median_wave GE max( robust_wave ), n_red )
    index_bad = where( median_mask GT 0, n_pix_bad, $
        complement=index_good, ncomplement=n_pix_good )
    index_inter  = findex( robust_wave, median_wave ) 
    robust_inter = interpolate( robust_arr, index_inter )
    robust_arr   = robust_inter
    robust_wave  = median_wave

    ;; Mask array for robust mean spectrum 
    robust_mask  = median_mask
    if ( n_blu NE 0 ) then begin 
        robust_mask[ index_blu ] = 1 
    endif 
    if ( n_red NE 0 ) then begin 
        robust_mask[ index_red ] = 1 
    endif 

    ;; Save the spectra to .txt file
    median_txt = median_output
    robust_txt = robust_output
    strreplace, median_txt, '.fits', '.txt'
    strreplace, robust_txt, '.fits', '.txt'

    hs_spec_to_txt, median_wave, median_arr, median_txt, $
        error=median_sig, mask=median_mask
    hs_spec_to_txt, robust_wave, robust_arr, robust_txt, $
        error=median_sig, mask=robust_mask

    ;; Save a summary file of FITS format
    sum_file = data_home + sample + '_coadd.fits' 
    sum_struc = { n_spec:n_spec, n_boot:n_boot, n_pix:n_pix_median, $
        sig_convol:sig_convol, $ 
        min_rest:min_rest, max_rest:max_rest, $ 
        min_norm:min_norm, max_norm:max_norm, $
        wave:median_wave,  frac:prep_frac,    snr:prep_s2nr, $ 
        median_arr:median_arr, median_sig:median_sig, $ 
        median_med:median_med, median_avg:median_avg, $ 
        median_mask:median_mask, $
        median_min:median_min, median_max:median_max, $ 
        robust_arr:robust_arr, robust_mask:robust_mask, $ 
        lquar:prep_lquar, uquar:prep_uquar, $
        lifen:prep_lifen, uifen:prep_uifen, $
        lofen:prep_lofen, uofen:prep_uofen }
    mwrfits, sum_struc, sum_file, /create, /silent

    ;; Make a summary plot
    index_list = 'hs_index_plot.lis' 
    if keyword_set( avg_boot ) then begin
        hs_coadd_sdss_plot, sum_file, index_list=index_list, $
            prefix=prefix, /avg_boot, hvdisp_home=hvdisp_home, data_dir=data_dir
    endif else begin 
        hs_coadd_sdss_plot, sum_file, index_list=index_list, $
            prefix=prefix, hvdisp_home=hvdisp_home, data_dir=data_dir
    endelse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end
