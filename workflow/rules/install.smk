rule install_amrfinder_db:
    output:
        setup = "resources/database/amr/amrfinder.setup"
    conda:
        "../envs/amrfinder.yml"
    shell:
        """
        amrfinder -u > {output.setup} 2>&1
        """


rule install_pymlst_db:
    output:
        pymlst_db = "resources/database/pyMLST/pymlst.db"
    conda:
        "../envs/pymlst.yml"
    params:
        species = config['configuration']['species']
    shell:
        """
        claMLST import {output.pymlst_db} {params.species}
        """


rule install_checkm2_db:
    output:
        checkm2_db = "resources/database/checkm2/CheckM2_database/uniref100.KO.1.dmnd"
    conda:
        "../envs/checkm2.yml"
    params:
        checkm2_dir = "resources/database/checkm2"
    shell:
        """
        checkm2 database --download --path {params.checkm2_dir}
        """

