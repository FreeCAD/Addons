
> [!CAUTION]
> Work-In-Progress Do Not Submit Issues / Pull Requests!

<br/>

<div align = center >

# Addon Index

This repository contains the metadata of the  
official addon index and related resources.

<br/>

[![Button Documentation]][Documentation]

</div>

## Data

The following metadata is stored:

-   [`Index.json`][Index]   
    List of known addons.

-   [`Python`][Python]  
    Version specific metadata.

    -   [`Allowed-Packages`][Packages]  
        List of allowed Python packages.

    -   [`constraints.txt`][Constraints]   
        Constraints of the Python packages.

    -   [`pyproject.toml`][Project]  
        Python environment configuration.

<!----------------------------------------------------------------------------->

[Constraints]: ./Data/Python/3.14/constraints.txt
[Packages]: ./Data/Python/3.14/Allowed-Packages
[Project]: ./Data/Python/3.14/pyproject.toml
[Python]: ./Data/Python
[Index]: ./Data/Index.json

<!----------------------------------------------------------------------------->

[Button Documentation]: https://img.shields.io/badge/Documentation-3b8ad9?style=for-the-badge&logoColor=white&logo=buffer

[Documentation]: https://github.com/FreeCAD/Addon-Academy/tree/Latest/Pages/Topics/Addon-Index
