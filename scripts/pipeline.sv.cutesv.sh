# need manually activate sv
# conda activate sv

path_data_raw=/$PATH_SAVE_DATA//0_raw
path_data=/$PATH_SAVE_DATA//1_mapping
path_save=/$PATH_SAVE_DATA//2_sv

path_genomics=/$PATH_SAVE_DATA//GRCh38.primary_assembly.genome.fa

nthreads=40
tag_method='cuteSV'

list_sample=('N01' 'N02' 'N03' 'N04')

# align
for sampleID in ${list_sample[@]}; do
  if [ -d $path_data_raw/$sampleID ]; then
    echo $sampleID

    bam_file=$path_data/minimap/$sampleID.sorted.bam

    if [ -f $bam_file ]; then
      path_save_vcf=$path_save/$sampleID/$tag_method

      if [ ! -d $path_save_vcf ]; then
        mkdir -p $path_save_vcf
      fi

      ##minimap + sniffles
      if [ ! -f $path_save_vcf/$sampleID.$tag_method.vcf ]; then
        cuteSV --threads $nthreads \
          --sample $sampleID \
          --min_support 5 \
          --report_readid \
          --genotype --min_size 50 \
          --max_cluster_bias_INS 100 \
          --diff_ratio_merging_INS 0.3 --max_cluster_bias_DEL 100 --diff_ratio_merging_DEL 0.3 \
          $bam_file $path_genomics $path_save_vcf/$sampleID.$tag_method.vcf $path_save_vcf/
      fi
    fi
  fi
done
