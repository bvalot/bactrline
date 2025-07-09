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
        pymlst_db =  config['configuration']['pymlst_db']
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
        checkm2_db = config['configuration']['checkm2_db']
    conda:
        "../envs/checkm2.yml"
    params:
        checkm2_dir = os.path.dirname(config['configuration']['checkm2_db']).rstrip('CheckM2_database')
    shell:
        """
		checkm2 database --download --path {params.checkm2_dir}
        """

