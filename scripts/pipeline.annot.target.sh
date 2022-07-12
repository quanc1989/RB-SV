path_data=$PATH_SAVE_DATA

list_group=('groupA' 'groupB')
for vcf_target in ${list_group[@]}; do
  $ANNOTSV/bin/AnnotSV \
    -SVinputFile $path_data/$vcf_target.vcf.gz \
    -outputDir $path_data/ \
    -outputFile $vcf_target.AnnotSV.tsv \
    -promoterSize 2000 \
    -overlap 50 \
    -genomeBuild GRCh38 \
    -annotationMode full
  # knotAnnotSV
  perl /home/dell/softwares/knotAnnotSV/knotAnnotSV.pl \
    --configFile /home/dell/softwares/knotAnnotSV/config_AnnotSV.yaml \
    --annotSVfile $path_data/$vcf_target.AnnotSV.tsv \
    --outDir $path_data/ \
    --outPrefix $path_data/$vcf_target.AnnotSV \
    --genomeBuild hg38
done
