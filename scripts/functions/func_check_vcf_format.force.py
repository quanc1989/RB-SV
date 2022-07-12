import configargparse
from Bio import SeqIO


def config_opts():
    parser = configargparse.ArgumentParser(
        description='func_check_vcf_format.force.py',
        config_file_parser_class=configargparse.YAMLConfigFileParser,
        formatter_class=configargparse.ArgumentDefaultsHelpFormatter)
    parser.add('-v', '--vcf', required=True,
               help='vcf source path')
    parser.add('-p', '--prefix', required=True,
               help='invalid vcf save prefix')
    # parser.add('-r', '--reference', required=True,
    #            help='genome reference to check vcf sequence')
    parser.add('-m', '--module', required=True,
               help='path for the original vcf for force-calling')
    return parser


if __name__ == '__main__':

    parser = config_opts()
    opt = parser.parse_args()

    # record_dict = SeqIO.to_dict(SeqIO.parse(opt.reference, "fasta"))

    list_svtype = ['DEL', 'INS', 'DUP', 'INV', 'TRA']
    list_svtype_extra = []

    dict_origin_vcf = {}
    with open(opt.module, 'r') as file_origin_vcf:
        while True:
            line = file_origin_vcf.readline().strip()
            if line:
                if not line.startswith('#'):
                    vcf_array = line.split('\t')

                    chrom = vcf_array[0]
                    pos = vcf_array[1]
                    svid = vcf_array[2]
                    ref = vcf_array[3]
                    alt = vcf_array[4]

                    svtype = [x.split('=')[1] for x in vcf_array[7].split(';') if 'SVTYPE=' in x][0]
                    pos_end = [x.split('=')[1] for x in vcf_array[7].split(';') if 'END=' in x][0]
                    svlen = [x.split('=')[1] for x in vcf_array[7].split(';') if 'SVLEN=' in x][0]

                    symbol_sv = chrom + '_' + pos + '_' + svtype

                    if symbol_sv not in dict_origin_vcf:
                        dict_origin_vcf[symbol_sv] = {
                            'ref': ref,
                            'alt': alt,
                            'svtype': svtype,
                            'len': svlen,
                            'id': svid,
                            'end': pos_end
                        }
                        # print(symbol_sv)
            else:
                break

    with open(opt.vcf, 'r') as file_read, open(opt.prefix + '.correct.log', 'w') as file_write, \
            open(opt.prefix + '.correct.vcf', 'w') as file_write_correct:
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
                    supp_origin = [x.split('=')[1] for x in vcf_array[7].split(';') if 'SUPP=' in x][0]
                    supp_vec_origin = [x.split('=')[1] for x in vcf_array[7].split(';') if 'SUPP_VEC=' in x][0]

                    if svtype not in list_svtype:
                        file_write.writelines('\t'.join([chrom, pos, svid]) + '\t not in svtype\n')
                    else:
                        symbol_sv = chrom + '_' + str(int(pos) - 1) + '_' + svtype
                        symbol_sv_alt = symbol_sv

                        if svtype == 'INS':
                            symbol_sv_alt = chrom + '_' + str(int(pos) - 1) + '_DUP'
                        if svtype == 'DUP':
                            symbol_sv_alt = chrom + '_' + str(int(pos) - 1) + '_INS'

                        flag_check_svtype = False
                        flag_check_svtype_alt = False

                        if symbol_sv in dict_origin_vcf:
                            flag_check_svtype = True
                            dict_tmp = dict_origin_vcf[symbol_sv]
                        elif symbol_sv_alt in dict_origin_vcf:
                            flag_check_svtype_alt = True
                            if svtype == 'INS':
                                file_write.writelines('\t'.join([chrom, pos, svtype]) + '\t DUP convert to INS\n')
                            if svtype == 'DUP':
                                file_write.writelines('\t'.join([chrom, pos, svtype]) + '\t INS convert to DUP\n')
                            dict_tmp = dict_origin_vcf[symbol_sv_alt]

                        if flag_check_svtype or flag_check_svtype_alt:
                            if abs(int(svlen)) == abs(int(dict_tmp['len'])) or abs((int(pos_end) - int(pos))) == abs(
                                    int(dict_tmp['len'])) or svtype == 'INS':

                                vcf_array[1] = str(int(pos) - 1)
                                vcf_array[3] = dict_tmp['ref']

                                if flag_check_svtype_alt:
                                    if svtype == 'INS':
                                        svlen_corrected = str(len(vcf_array[4]))
                                        pos_end_corrected = vcf_array[1]
                                    if svtype == 'DUP':
                                        svlen_corrected = str(abs(int(dict_tmp['len'])))
                                        pos_end_corrected = str(int(pos_end) - 1)
                                else:
                                    vcf_array[4] = dict_tmp['alt']
                                    svlen_corrected = str(abs(int(dict_tmp['len'])))
                                    pos_end_corrected = dict_tmp['end']

                                if svtype != 'TRA':
                                    vcf_array[2] = "%s-%s-%s-%s" % (chrom, vcf_array[1], svtype, svlen_corrected)
                                else:
                                    vcf_array[2] = "%s-%s-%s-%s-%s" % (
                                        chrom, vcf_array[1], 'BND', chr2, pos_end_corrected)

                                if int(svlen_corrected) > 50 or svtype == 'TRA':

                                    supp_sum = 0
                                    supp_vec = ''

                                    for index_col in [9, 10, 11]:
                                        if vcf_array[index_col].startswith('0/1') or vcf_array[index_col].startswith(
                                                '1/1'):
                                            supp_sum += 1
                                            supp_vec += '1'
                                        else:
                                            supp_vec += '0'

                                    vcf_array[7] = vcf_array[7].replace('SUPP=' + supp_origin,
                                                                        'SUPP=' + str(supp_sum))
                                    vcf_array[7] = vcf_array[7].replace('SUPP_VEC=' + supp_vec_origin,
                                                                        'SUPP_VEC=' + supp_vec)
                                    vcf_array[7] = vcf_array[7].replace('SVLEN=' + svlen,
                                                                        'SVLEN=' + svlen_corrected)
                                    vcf_array[7] = vcf_array[7].replace('END=' + pos_end,
                                                                        'END=' + pos_end_corrected)
                                    if svtype == 'TRA':
                                        vcf_array[7] = vcf_array[7].replace('SVTYPE=' + svtype,
                                                                            'SVTYPE=' + 'BND')
                                    file_write_correct.writelines('\t'.join(vcf_array) + '\n')

                                else:
                                    file_write.writelines('\t'.join([chrom, pos, svtype]) + '\t not valid len\n')
                            else:
                                file_write.writelines('\t'.join([chrom, pos, svtype]) + '\t not valid position\n')
                        else:
                            file_write.writelines('\t'.join([chrom, pos, svtype]) + '\t not valid symbol_sv\n')


            else:
                break
