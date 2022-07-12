# need manually activate sv
# conda activate sv;
path_data_raw=$PATH_SAVE_DATA//0_raw
path_data=$PATH_SAVE_DATA/1_mapping
path_save=$PATH_SAVE_DATA/2_sv

path_genomics=$PATH_SAVE_DATA//GRCh38.primary_assembly.genome.fa

# align
for sampleID in $(ls $path_data_raw); do
  if [ -d $path_data_raw/$sampleID ]; then
    echo $sampleID

    bam_file=$path_data/minimap/$sampleID.sorted.bam

    if [ -f $bam_file ]; then

      path_save_vcf=$path_save/$sampleID/svim

      if [ ! -d $path_save_vcf ]; then
        mkdir -p $path_save_vcf
      fi

      if [ ! -f $path_save_vcf/variants.vcf ]; then
        ##minimap2 + svim
        svim alignment --sample $sampleID \
          --insertion_sequence \
          --sample $sampleID \
          --min_sv_size 50 \
          --minimum_depth 5 \
          --read_names \
          --heterozygous_threshold 0.3 \
          $path_save_vcf $bam_file $path_genomics
      fi

      if [ ! -f $path_save_vcf/$sampleID.svim.vcf ]; then
        ## need filter QUAL and SUPPORT
        bcftools view -i 'QUAL >= 10 & SUPPORT >= 5' $path_save_vcf/variants.vcf >$path_save_vcf/$sampleID.svim.vcf
      fi
    fi
  fi
done
