##### ibd segment detection

# do something about the min-mac from min-maf params

### perform ibd segment detection
### using hap-ibd software

# for reference samples
rule hapibd_ref:
    input:
        refvcf='{study}/gtdata/refpop/chr{num}.rephased.vcf.gz',
        chrmap='{study}/maps/chr{num}.map',
    output:
        refhap='{study}/ibdsegs/chr{num}.rephased.ref.hapibd.ibd.gz',
    params:
        software=str(config['change']['pipe']['software']),
        minout=str(config['fixed']['hapibd-parameters']['min-output']),
        minextend=str(config['fixed']['hapibd-parameters']['min-extend']),
        minseed=str(config['fixed']['hapibd-parameters']['min-seed']),
        maxgap=str(config['fixed']['hapibd-parameters']['max-gap']),
        prog=str(config['fixed']['programs']['hapibd']),
        refout='{study}/ibdsegs/chr{num}.rephased.ref.hapibd',
        nthreads=str(config['change']['cluster-resources']['threads']),
        xmxmem=str(config['change']['cluster-resources']['xmxmem']),
        minmac=str(config['fixed']['hapibd-parameters']['min-mac']),
    shell:
        '''
        mkdir -p {wildcards.study}/ibdsegs
        java -Xmx{params.xmxmem}g -jar {params.software}/{params.prog} \
            gt={input.refvcf} \
            map={input.chrmap} \
            out={params.refout} \
            min-output={params.minout} \
            min-extend={params.minextend} \
            min-seed={params.minseed} \
            max-gap={params.maxgap} \
            min-mac={params.minmac} \
            nthreads={params.nthreads}
        '''

# for admixed samples
rule hapibd_adx:
    input:
        adxvcf='{study}/gtdata/adxpop/chr{num}.rephased.vcf.gz',
        chrmap='{study}/maps/chr{num}.map',
    output:
        adxhap='{study}/ibdsegs/chr{num}.rephased.adx.hapibd.ibd.gz',
    params:
        software=str(config['change']['pipe']['software']),
        minout=str(config['fixed']['hapibd-parameters']['min-output']),
        minextend=str(config['fixed']['hapibd-parameters']['min-extend']),
        minseed=str(config['fixed']['hapibd-parameters']['min-seed']),
        maxgap=str(config['fixed']['hapibd-parameters']['max-gap']),
        prog=str(config['fixed']['programs']['hapibd']),
        adxout='{study}/ibdsegs/chr{num}.rephased.adx.hapibd',
        nthreads=str(config['change']['cluster-resources']['threads']),
        xmxmem=str(config['change']['cluster-resources']['xmxmem']),
        minmac=str(config['fixed']['hapibd-parameters']['min-mac']),
    shell:
        '''
        mkdir -p {wildcards.study}/ibdsegs
        java -Xmx{params.xmxmem}g -jar {params.software}/{params.prog} \
            gt={input.adxvcf} \
            map={input.chrmap} \
            out={params.adxout} \
            min-output={params.minout} \
            min-extend={params.minextend} \
            min-seed={params.minseed} \
            max-gap={params.maxgap} \
            min-mac={params.minmac} \
            nthreads={params.nthreads}
        '''