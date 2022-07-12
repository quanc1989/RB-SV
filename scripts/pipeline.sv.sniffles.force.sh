path_data=$PATH_SAVE_DATA//2_sv
path_data_raw=$PATH_SAVE_DATA//0_raw
path_data_mapping=$PATH_SAVE_DATA//1_mapping

nthreads=40

if [ -f $path_data/merge.force.vcf.list ]; then
  rm $path_data/merge.force.vcf.list
fi

if [ -f $path_data/merge.force.sort.vcf.gz.list ]; then
  rm $path_data/merge.force.sort.vcf.gz.list
fi

for sampleID in $(ls $path_data_raw); do
  if [ -d $path_data_raw/$sampleID ]; then
    echo $sampleID

    bam_file=$path_data_mapping/minimap/$sampleID.sorted.addMD.bam

    if [ -f $bam_file ]; then
      path_save_vcf=$path_data/$sampleID/sniffles

      if [ ! -d $path_save_vcf ]; then
        mkdir -p $path_save_vcf
      fi

      ##minimap + sniffles
      if [ ! -f $path_save_vcf/$sampleID.sniffles.force.vcf ]; then
        cmd_sniffles="sniffles -s 5 -t "$nthreads" -l 50 -n -1 -m "$bam_file" -v "$path_save_vcf/$sampleID.sniffles.force.vcf" --Ivcf "$path_data"/merge.correct.vcf"
        echo $cmd_sniffles
        sniffles -s 5 -t $nthreads -l 50 -n -1 -m $bam_file -v $path_save_vcf/$sampleID.sniffles.force.vcf --Ivcf $path_data/merge.correct.vcf
      fi

      if [ ! -f $path_save_vcf/$sampleID.sniffles.force.sort.vcf.gz ]; then
        bcftools sort -O z -o $path_save_vcf/$sampleID.sniffles.force.sort.vcf.gz $path_save_vcf/$sampleID.sniffles.force.vcf;
        bcftools index $path_save_vcf/$sampleID.sniffles.force.sort.vcf.gz;
      fi;

      echo $path_save_vcf/$sampleID.sniffles.force.sort.vcf.gz >> $path_data/merge.force.sort.vcf.gz.list
      echo $path_save_vcf/$sampleID.sniffles.force.vcf >> $path_data/merge.force.vcf.list
    fi
  fi
done

if [ ! -f $path_data/merge.force.vcf ];then
#  bcftools merge -m id -O v -l $path_data/merge.force.vcf.list -o $path_data/merge.force.vcf
  SURVIVOR merge $path_data/merge.force.vcf.list 1000 -1 1 1 0 50 $path_data/merge.force.vcf
fi;
