# need manually activate sv
# conda activate sv

path_smrtcmds=/opt/pacbio/smrtlink/smrtcmds/bin

path_data_raw=$PATH_SAVE_DATA//0_raw
path_data=$PATH_SAVE_DATA//1_mapping
path_save=$PATH_SAVE_DATA//2_sv

path_genomics=$PATH_SAVE_DATA//GRCh38.primary_assembly.genome.fa

# align
for sampleID in $(ls $path_data_raw); do
  if [ -d $path_data_raw/$sampleID ]; then

    echo $sampleID

    bam_file=$path_data/pbmm2/$sampleID.sorted.bam

    if [ -f $bam_file ]; then

      path_save_vcf=$path_save/$sampleID/pbsv

      if [ ! -d $path_save_vcf ]; then
        mkdir -p $path_save_vcf
      fi

      ##pbmm2 + pbsv
      if [ ! -f $path_save_vcf/$sampleID.pbsv.vcf ]; then

        str_svsig_list=""
        for movie_bam in $(ls $path_data/pbmm2/$sampleID/*.bam); do
          movie_bam_filename=$(basename $movie_bam .bam)

          if [ ! -f $path_save_vcf/$movie_bam_filename.svsig.gz ]; then
            $path_smrtcmds/pbsv discover \
              --tandem-repeats $path_smrtcmds/human_GRCh38_no_alt_analysis_set.trf.bed \
              $movie_bam $path_save_vcf/$movie_bam_filename.svsig.gz
          fi
          str_svsig_list=$path_save_vcf"/"$movie_bam_filename.svsig.gz" "$str_svsig_list
        done

        if [ ! -f $path_save_vcf/$sampleID.pbsv.vcf ]; then
          $path_smrtcmds/pbsv call \
            --gt-min-reads 5 \
            --call-min-reads-one-sample 5 \
            --call-min-reads-all-samples 5 \
            -j 40 \
            -m 50 \
            $path_genomics $str_svsig_list $path_save_vcf/$sampleID.pbsv.vcf
        fi
      fi
    fi
  fi
done
