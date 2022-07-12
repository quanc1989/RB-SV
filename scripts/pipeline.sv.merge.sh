path_data=$PATH_SAVE_DATA/2_sv
path_data_raw=$PATH_SAVE_DATA/0_raw
path_data_mapping=$PATH_SAVE_DATA/1_mapping

nthreads=40
list_method=("sniffles" "svim" "pbsv")

if [ -f $path_data/merge.vcf.list ]; then
  rm $path_data/merge.vcf.list
fi

for sampleID in $(ls $path_data); do
  if [ -d $path_data/$sampleID ]; then
    echo $sampleID
    rm $path_data/$sampleID/merge.vcf.list
    for method_sv in ${list_method[@]}; do
      if [ -d $path_data/$sampleID/$method_sv ]; then
        echo $method_sv
        file_sv=$path_data/$sampleID/$method_sv/$sampleID.$method_sv.vcf
        echo $file_sv >>$path_data/$sampleID/merge.vcf.list
      fi
    done

    SURVIVOR merge $path_data/$sampleID/merge.vcf.list 1000 2 1 1 0 50 $path_data/$sampleID/$sampleID.merge.vcf
    echo $path_data/$sampleID/$sampleID.merge.vcf >>$path_data/merge.vcf.list
  fi
done

SURVIVOR merge $path_data/merge.vcf.list 1000 1 1 0 0 50 $path_data/merge.vcf
