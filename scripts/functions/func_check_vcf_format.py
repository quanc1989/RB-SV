import configargparse
from Bio import SeqIO


def config_opts():
    parser = configargparse.ArgumentParser(
        description='func_check_vcf_format.py',
        config_file_parser_class=configargparse.YAMLConfigFileParser,
        formatter_class=configargparse.ArgumentDefaultsHelpFormatter)
    parser.add('-v', '--vcf', required=True,
               help='vcf source path')
    parser.add('-p', '--prefix', required=True,
               help='invalid vcf save prefix')
    parser.add('-r', '--reference', required=True,
               help='genome reference to check vcf sequence')
    return parser


if __name__ == '__main__':

    parser = config_opts()
    opt = parser.parse_args()

    record_dict = SeqIO.to_dict(SeqIO.parse(opt.reference, "fasta"))

    list_svtype = ['DEL', 'INS', 'DUP', 'INV', 'TRA']
    list_svtype_extra = []

    dict_res = {}
    for svtype in list_svtype:
        dict_res[svtype] = {'num': 0, 'invalid': 0, 'corrected': 0}

    with open(opt.vcf, 'r') as file_read, open(opt.prefix + '.correct.log', 'w') as file_write, open(
            opt.prefix + '.correct.vcf', 'w') as file_write_correct:
        while True:
            line = file_read.readline().strip()
            if line:
                if line.startswith('#'):
                    file_write_correct.writelines(line + '\n')
                    continue
                elif line:
                    vcf_array = line.split('\t')

                    chrom = vcf_array[0]
                    pos = vcf_array[1]
                    svid = vcf_array[2]

                    svtype = [x.split('=')[1] for x in vcf_array[7].split(';') if 'SVTYPE=' in x][0]
                    chr2 = [x.split('=')[1] for x in vcf_array[7].split(';') if 'CHR2=' in x][0]
                    pos_end = [x.split('=')[1] for x in vcf_array[7].split(';') if 'END=' in x][0]
                    svlen = [x.split('=')[1] for x in vcf_array[7].split(';') if 'SVLEN=' in x][0]

                    if svtype not in list_svtype:
                        if svtype not in list_svtype_extra:
                            file_write.writelines('\t'.join([chrom, pos, svid]) + '\t not in svtype\n')
                            list_svtype_extra.append(svtype)
                    else:
                        dict_res[svtype]['num'] += 1

                        if svtype == 'INS':

                            if len(vcf_array[4]) < 50:
                                file_write.writelines('\t'.join([chrom, pos, svid]) + '\t not valid INS\n')
                            else:
                                alt = vcf_array[4]
                                vcf_array[3] = alt[0]

                                if alt[0] != str(record_dict[chrom][(int(pos) - 1):int(pos)].seq):
                                    file_write.writelines('\t'.join([chrom, pos, svid, alt[0], str(record_dict[chrom][
                                                                                                   (int(pos) - 1):int(
                                                                                                       pos)].seq)]) + '\t not valid ref sequence\n')
                                    vcf_array[3] = 'N'

                                svlen_corrected = len(vcf_array[4])
                                vcf_array[7] = vcf_array[7].replace('SVLEN=' + svlen,
                                                                    'SVLEN=' + str(svlen_corrected))

                                vcf_array[2] = "%s-%s-%s-%d" % (chrom, pos, svtype, svlen_corrected)
                                file_write_correct.writelines('\t'.join(vcf_array) + '\n')

                        elif svtype == 'DEL':
                            # file_write.writelines(line + '\n')
                            # else:
                            ref = str(record_dict[chrom][(int(pos) - 1):(int(pos_end) - 1)].seq)
                            vcf_array[3] = ref
                            vcf_array[4] = ref[0]

                            svlen_corrected = len(vcf_array[3])
                            vcf_array[7] = vcf_array[7].replace('SVLEN=' + svlen,
                                                                'SVLEN=' + str(svlen_corrected))
                            vcf_array[2] = "%s-%s-%s-%d" % (chrom, pos, svtype, svlen_corrected)
                            file_write_correct.writelines('\t'.join(vcf_array) + '\n')

                        elif svtype == 'DUP':
                            vcf_array[3] = 'N'
                            vcf_array[4] = '<DUP>'
                            svlen_corrected = int(pos_end) - int(pos)
                            vcf_array[7] = vcf_array[7].replace('SVLEN=' + svlen,
                                                                'SVLEN=' + str(svlen_corrected))
                            vcf_array[2] = "%s-%s-%s-%d" % (chrom, pos, svtype, svlen_corrected)
                            file_write_correct.writelines('\t'.join(vcf_array) + '\n')

                        elif svtype == 'INV':
                            vcf_array[3] = 'N'
                            vcf_array[4] = '<INV>'
                            svlen_corrected = int(pos_end) - int(pos)
                            vcf_array[7] = vcf_array[7].replace('SVLEN=' + svlen,
                                                                'SVLEN=' + str(svlen_corrected))
                            vcf_array[2] = "%s-%s-%s-%d" % (chrom, pos, svtype, svlen_corrected)
                            file_write_correct.writelines('\t'.join(vcf_array) + '\n')

                        elif svtype == 'TRA':
                            vcf_array[2] = "%s-%s-%s-%s-%s" % (chrom, pos, svtype, chr2, pos_end)
                            file_write_correct.writelines('\t'.join(vcf_array) + '\n')
                        else:
                            file_write.writelines('_'.join([chrom, pos, svid]) + '\t unknown svtype\n')

            else:
                break
