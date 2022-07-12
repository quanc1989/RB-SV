path_genomics=/$PATH_SAVE_DATA/GRCh38.primary_assembly.genome.fa
nthreads=40

path_data=$PATH_SAVE_DATA/0_raw
path_save=$PATH_SAVE_DATA/minimap

if [ ! -d $path_save ]; then
  mkdir $path_save
fi

# align
for sampleID in $(ls $path_data); do
  if [ -d $path_data/$sampleID ]; then

    echo $sampleID

    #mapping minimap2
    if [ ! -f $path_save/$sampleID.sorted.bam ]; then
      minimap2 --MD -ax map-ont $path_genomics $path_data/$sampleID/$sampleID.filt.fq |
        samtools sort -@ $nthreads -o $path_save/$sampleID.sorted.bam
      samtools index -@ $nthreads $path_save/$sampleID.sorted.bam;
    fi
  fi
done
