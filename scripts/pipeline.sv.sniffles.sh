# need manually activate sv
# conda activate sv

path_data_raw=$PATH_SAVE_DATA//0_raw
path_data=/$PATH_SAVE_DATA//1_mapping
path_save=$PATH_SAVE_DATA//2_sv

path_genomics=$PATH_SAVE_DATA//GRCh38.primary_assembly.genome.fa
nthreads=40

# align
for sampleID in $(ls $path_data_raw); do
  if [ -d $path_data_raw/$sampleID ]; then
    echo $sampleID

    bam_file=$path_data/minimap/$sampleID.sorted.bam
#    bam_file=$path_data/minimap/$sampleID.sorted.addMD.bam

    if [ -f $bam_file ];then
      path_save_vcf=$path_save/$sampleID/sniffles

      if [ ! -d $path_save_vcf ];then
        mkdir -p $path_save_vcf;
      fi;

      ##minimap + sniffles
      if [ ! -f $path_save_vcf/$sampleID.sniffles.vcf ];then
        cmd_sniffles="sniffles -s 5 -t "$nthreads" -l 50 -n -1 -m "$bam_file" -v "$path_save_vcf/$sampleID.sniffles.vcf
        echo $cmd_sniffles;
        sniffles -s 5 -t $nthreads -l 50 -n -1 -m $bam_file -v $path_save_vcf/$sampleID.sniffles.vcf
      fi;
    fi;
  fi;
done;

