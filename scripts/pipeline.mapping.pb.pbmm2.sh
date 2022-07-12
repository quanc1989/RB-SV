path_smrtcmds=/opt/pacbio/smrtlink/smrtcmds/bin
path_genomics=/$PATH_SAVE_DATA/GRCh38.primary_assembly.genome.fa
nthreads=40

# index the ref genome
if [ ! -f $path_genomics.mmi ];then
  $path_smrtcmds/pbmm2 index $path_genomics $path_genomics.mmi;
fi;

path_data=$PATH_SAVE_DATA//0_raw
path_save=$PATH_SAVE_DATA//pbmm2

if [ ! -d $path_save ];then
  mkdir $path_save;
fi;

# align
for sampleID in $(ls $path_data);do
  if [ -d $path_data/$sampleID ];then

    echo $sampleID;

    if [ ! -d $path_save/$sampleID ];then
      mkdir $path_save/$sampleID;
    fi;

    for bam_subreads in $(ls $path_data/$sampleID/*.bam );do

      filename_subreads=`basename $bam_subreads`

      echo $path_smrtcmds"/pbmm2 align "$path_genomics".mmi "$bam_subreads" "$path_save"/"$sampleID"/"$filename_subreads" --sort --bam-index BAI -j "$nthreads" -J "$nthreads" --median-filter"

      $path_smrtcmds/pbmm2 align \
      $path_genomics.mmi $bam_subreads $path_save/$sampleID/$filename_subreads \
      --sort --bam-index BAI -j $nthreads -J $nthreads --median-filter
    done;

    num_bam=`ls $path_save/$sampleID/*.bam | wc -l`;
    if [ $num_bam -gt 1 ];then
      ls $path_save/$sampleID/*.bam > $path_save/$sampleID/bam.files
      samtools merge -@ $nthreads -b $path_save/$sampleID/bam.files $path_save/$sampleID.bam;
      samtools sort $path_save/$sampleID.bam -@ $nthreads -o $path_save/$sampleID.sorted.bam;
      samtools index $path_save/$sampleID.sorted.bam;
    else
      bam_align_subreads=$(ls $path_save/$sampleID/*.bam)
      cp $bam_align_subreads $path_save/$sampleID.sorted.bam
      cp $bam_align_subreads.bai $path_save/$sampleID.sorted.bam.bai
    fi;
  fi;
done;


# align

