##### haplotype phasing

### rephasing

# remove the phase in reference samples
rule unphase_ref:
    input:
        refvcf='{study}/gtdata/refpop/chr{num}.vcf.gz',
    output:
        refvcf='{study}/gtdata/refpop/chr{num}.unphased.vcf.gz',
    params:
        software=str(config['change']['pipe']['software']),
        rmphase=str(config['fixed']['programs']['remove-phase']),
    shell:
        '''
        zcat {input.refvcf} | java -jar {params.software}/{params.rmphase} 30293 | bgzip -c > {output.refvcf}
        '''

# remove phase in admixed samples
rule unphase_adx:
    input:
        adxvcf='{study}/gtdata/adxpop/chr{num}.vcf.gz',
    output:
        adxvcf='{study}/gtdata/adxpop/chr{num}.unphased.vcf.gz',
    params:
        software=str(config['change']['pipe']['software']),
        rmphase=str(config['fixed']['programs']['remove-phase']),
    shell:
        '''
        zcat {input.adxvcf} | java -jar {params.software}/{params.rmphase} 30598 | bgzip -c > {output.adxvcf}
        '''

rule merge_vcfs:
    input:
        adxvcf='{study}/gtdata/adxpop/chr{num}.unphased.vcf.gz',
        refvcf='{study}/gtdata/refpop/chr{num}.unphased.vcf.gz',
    output:
        allvcf='{study}/gtdata/all/chr{num}.unphased.vcf.gz',
        intersection='{study}/gtdata/all/chr{num}.intersection.Rfile.txt'
    params:
        minmac=str(config['change']['bcftools-parameters']['c-min-mac']),
        script=str(config['change']['pipe']['scripts'] + '/shared.py'),
    shell:
        '''
        tabix -fp vcf {input.adxvcf}
        tabix -fp vcf {input.refvcf}
        bcftools query -f "%CHROM\t%POS\n" > {input.adxvcf}.pos
        bcftools query -f "%CHROM\t%POS\n" > {input.refvcf}.pos
        python {params.script} {input.adxvcf}.pos {input.refvcf}.pos {output.intersection}
        bcftools merge -c {params.minmac}:nonmajor -O z -R {output.intersection} -o {output.allvcf} {input.adxvcf} {input.refvcf}
        '''

# another phasing strategy
# phase using ref and admixs all together
# helps w/ phase consistency
# i reviewed a paper that says 
# this controls switch errors better
rule phase_all:
    input:
        allvcf='{study}/gtdata/all/chr{num}.unphased.vcf.gz',
        chrmap='{study}/maps/chr{num}.map',
    output:
        allvcf='{study}/gtdata/all/chr{num}.rephased.vcf.gz',
    params:
        software=str(config['change']['pipe']['software']),
        phase=str(config['fixed']['programs']['beagle']),
        allvcfout='{study}/gtdata/all/chr{num}.rephased',
        xmx=config['change']['cluster-resources']['xmxmem'],
        thr=config['change']['cluster-resources']['threads'],
        excludesamples=str(config['change']['existing-data']['exclude-samples']),
    shell:
        '''
        java -Xmx{params.xmx}g -jar {params.software}/{params.phase} \
            gt={input.allvcf} \
            map={input.chrmap} \
            out={params.allvcfout} \
            nthreads={params.thr} \
            excludesamples={params.excludesamples}
        '''

# subset the phased files for admixed samples
rule subset_phased_adx:
    input:
        allvcf='{study}/gtdata/all/chr{num}.rephased.vcf.gz',
        adxsam='{study}/gtdata/adxpop/chr{num}.sample.txt'
    output:
        adxvcf='{study}/gtdata/adxpop/chr{num}.rephased.vcf.gz',
    shell:
        '''
        tabix -fp vcf {input.allvcf}
        bcftools view -S {input.adxsam} -O z -o {output.adxvcf} {input.allvcf}
        '''

# subset the phased files for reference samples
rule subset_phased_ref:
    input:
        allvcf='{study}/gtdata/all/chr{num}.rephased.vcf.gz',
        refsam='{study}/gtdata/refpop/chr{num}.sample.txt'
    output:
        refvcf='{study}/gtdata/refpop/chr{num}.rephased.vcf.gz',
    shell:
        '''
        tabix -fp vcf {input.allvcf}
        bcftools view -S {input.refsam} -O z -o {output.refvcf} {input.allvcf}
        '''

### initial phasing

rule phase_ref:
    input:
        adxvcf='{study}/gtdata/adxpop/chr{num}.vcf.gz',
        refvcf='{study}/gtdata/refpop/chr{num}.vcf.gz',
        chrmap='{study}/maps/chr{num}.map',
    output:
        refvcf='{study}/gtdata/adxpop/chr{num}.referencephased.vcf.gz',
    params:
        software=str(config['change']['pipe']['software']),
        phase=str(config['fixed']['programs']['beagle']),
        adxvcfout='{study}/gtdata/adxpop/chr{num}.referencephased',
        xmx=config['change']['cluster-resources']['xmxmem'],
        thr=config['change']['cluster-resources']['threads'],
        excludesamples=str(config['change']['existing-data']['exclude-samples']),
        impute=str(config['fixed']['beagle-parameters']['impute']),
    shell:
        '''
        java -Xmx{params.xmx}g -jar {params.software}/{params.phase} \
            gt={input.adxvcf} \
            ref={input.refvcf} \
            map={input.chrmap} \
            out={params.adxvcfout} \
            nthreads={params.thr} \
            excludesamples={params.excludesamples} \
            impute={params.impute}
        '''