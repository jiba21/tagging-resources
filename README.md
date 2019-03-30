# tagging-resources

# README #

Best Practices AWS to tag resources:

     https://d0.awsstatic.com/aws-answers/AWS_Tagging_Strategies.pdf
       
### Contenido ###

* forcetag-ec2-policy.json
* massive-tag-scripts

### Utilidades ###
    
* forcetag-ec2-policy.json

Esta política fuerza a los usuarios a añadir 3 Tags (Owner, Project, Name) en el momento de la creación del recurso EC2.
    
* massive-tag-scripts

    Scripts de tagueado masivo, los recursos que se pueden taguear:
    
        - AMI
        - EC2
        - EBS
        - Snapshots
        - VPC
        - Subnets
        - RDS 
        - S3  * Solo usar si no hay tags creados, se carga los existentes *

### Descripción TAGS ###

* Technical Tags            Description
 * Name                      Identificar el recurso.
 * Technology Name           Que tecnologia se usa (Sistema operativo, bbdd ...)
 * Application Role          Describir la función de la instancia: (ej. APP, SQL, FTP, WEB)
 * Environment               [DEV, TEST, PRO, PRE]
 * Creator                   Creador del Recurso


* Tags for Automation       Description
 * Backup                   [Lambda, N2W, S3]  - que sistema se usa para hacer el backup del recurso

* Business Tags             Description
 * Owner                     Identificar el responsable del recurso 
 * Cost Center               Indicar la unidad de la empresa asociada con el recurso.
 * Customer                  Identificar cliente o Grupo.
 * Project                   El nombre del proyecto del recurso.


 * Security Tags             Description
 * Confidentiality           El nivel de confidencialidad del recurso. limitar el acceso a los usuario, generando un rol especificando este tag.
 * Compliance                Identificar si un recurso necesita cumplir un requerimiento específico.
