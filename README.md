# RB-SV
Pipeline of structural-variation calling for Retinoblastoma samples

## Sample Information

| CustomerID | Name   | Group | SampleID | Data                  |
| --- |--------| --- | --- |-----------------------|
| FC_RB | 范宸乐    | RB | N02 | Nanopore sequencing   |
| FJ | 范家乐    | WT_RB | N01 | Nanopore sequencing   |
| ZJ | 朱玥雯之姐  | WT_RB_TSC | N03 | Nanopore sequencing   |
| ZY_RT | 朱玥雯    | RB_TSC | N04 | Nanopore sequencing   |
| unkown | unkown | unkown | BJ181303-02 | PacBio CLR sequencing |
| unkown | unkown    | unkown | HPDE6C7 | PacBio CLR sequencing   |
| unkown | unkown    | unkown | PANC1 | PacBio CLR sequencing  |

## Pipeline

A two-step structural variation (SV) detection pipeline was used for the dataset, 
i.e., breakpoints were first detected per each sample, and then merged to genotype for the population. 
Detailed information was described as follows.

1. Minimap2 was used to align each sample by nanopore sequencing to GRCh38 reference, using the default parameters of Minimap for ONT.

    ```shell
      minimap2 --MD -ax map-ont $PATH_REFERENCE_FASTA $PATH_NANOPORE_FASTQ |
        samtools sort -@ $NTHREADS -o $PATH_TO_SAVE_DATA/$RESULT_BAM
      samtools index -@ $NTHREADS $PATH_TO_SAVE_DATA/$RESULT_SORTED_BAM;
    ```
2. Pbmm2 was used to align each data by PacBio sequencing to GRCh38 reference.

    ```shell
      pbmm2 align $PATH_REFERENCE_MMI $PATH_PACBIO_BAM_SUBREADS $PATH_TO_SAVE_DATA/$RESULT_BAM \
      --sort --bam-index BAI -j $NTHREADS -J $NTHREADS --median-filter
    ```
   
3. 对于每一个样本，同时使用Sniffles，CuteSV和 SVIM三种软件进行SV检测。这些软件均与Minimap适配。对于每一种软件发现的每一个SV，要求长度在50bp以上，且至少有5个以上的支持该SV的读段。每个软件都需要记录插入序列以及支持该SV的读段ID。
4. 对于每一个样本，使用SURVIVOR合并三种方法检测到的SV，要求每个SV至少被两种软件检测到，并且相邻的SV之间要间隔1kbp以上。在同一个位置，不同软件检测到的SV不需要有一致的类型，也不需要有相同的方向，这是为了确保我们获取到尽可能多的高置信度的断点区域。最后使用SURVIVOR合并4个样本检测到的断点集合，每个断点必须至少有一个样本支持。
5. 最后，我们需要得到一个有完整分型的多样本数据集。 我们在所有这些潜在断点区域，对每一个样本重新运行 Sniffles进行SV的分型，然后使用 SURVIVOR合并在一起。 这一次，我们要求 SURVIVOR 只报告至少一个样本支持的 SV，而且必须有相同的SV类型。 此外，我们仍然使用了一个五个最小支持读段的硬阈值，并且所有小于该阈值的非缺失基因型都被修改为ref（0/0）。
6. 我们构建了Ensembl Canonical transcript for GRCh38，然后使用GATK中的svtk工具对所有SV所处的区域进行了注释。
7. 使用AnnotSV对所有SV进行了全面的注释，并且使用KnotAnnotSV对注释内容进行了可视化，便于查看。

![图1. SV检测流程。](plots/pipeline-sv-calling.png)

图1. SV检测流程。


## Software versions

| Softwares   | Version    |
|-------------|------------|
| Minimap     | 2.22-r1101 |
| pbmm2       | 1.5.0      |
| samtools    | 1.7        |
| htslib      | 1.7-2      |
| Sniffles    | 1.0.12     |
| CuteSV      | 1.0.8      |
| SVIM        | 2.0.0      |
| SURVIVOR    | 1.0.7      |
| GATK: svtk  | 0.1        |
| AnnotSV     | 3.0.9      |
| KnotAnnotSV | 1.1.1      |
| R           | 4.0.5      |
| Metascape   | 3.5        |
