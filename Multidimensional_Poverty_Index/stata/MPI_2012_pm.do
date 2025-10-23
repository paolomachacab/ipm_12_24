**************************************************************
* ÍNDICE DE POBREZA MULTIDIMENSIONAL (IPM) - BOLIVIA 2012
**************************************************************

clear all
set more off
version 17.0
set maxvar 32767

**************************************************************
* 1. CONFIGURACIÓN DE ENTORNO Y RUTAS
**************************************************************

* Definir ruta principal (carpeta local de trabajo)
global path "C:\Users\`c(username)'\Desktop\censo_2012"

* Crear carpeta si no existe
cap mkdir "$path"
cd "$path"

display "Carpeta de trabajo: $path"

**************************************************************
* 2. IMPORTACIÓN DE BASES CSV ORIGINALES
**************************************************************

* Importar PERSONA
capture confirm file "$path\PERSONA.csv"
if _rc == 0 {
    import delimited "$path\PERSONA.csv", clear varnames(1) encoding(UTF-8)
    compress
    save "$path\persona_2012.dta", replace
    display "Base PERSONA cargada y guardada correctamente."
}
else {
    di as error "No se encontró el archivo PERSONA.csv en $path"
    exit
}

* Importar VIVIENDA
capture confirm file "$path\VIVIENDA.csv"
if _rc == 0 {
    import delimited "$path\VIVIENDA.csv", clear varnames(1) encoding(UTF-8)
    compress
    save "$path\vivienda_2012.dta", replace
    display "Base VIVIENDA cargada y guardada correctamente."
}
else {
    di as error "No se encontró el archivo VIVIENDA.csv en $path"
    exit
}

**************************************************************
* 3. UNIÓN DE BASES PERSONA + VIVIENDA
**************************************************************

use "$path\persona_2012.dta", clear
merge m:1 vivienda_ref_id using "$path\vivienda_2012.dta"

tab _merge
/*
Interpretación:
  _merge == 3 → coincidencia en ambas bases (lo que necesitamos)
  _merge == 1 → personas sin vivienda
  _merge == 2 → viviendas sin personas (desocupadas)
*/

keep if _merge == 3
drop _merge

compress
save "$path\censo_2012.dta", replace
display "Unión completada exitosamente: censo_2012.dta creada en $path"

**************************************************************
* 4. CREACIÓN DE LAS 9 PRIVACIONES DEL IPM
**************************************************************

use "$path\censo_2012.dta", clear

**************************************************************
* DIMENSIÓN 1: PODER Y VOZ
**************************************************************

*-------------------------------------------------------------*
* 1. Documento de identidad: personas ≥6 años sin carnet
*-------------------------------------------------------------*
gen sin_carnet_ind = .
replace sin_carnet_ind = 1 if p25 >= 6 & p27 == 2
replace sin_carnet_ind = 0 if p25 >= 6 & p27 == 1
replace sin_carnet_ind = . if inlist(p27,0,9)
bys vivienda_ref_id: egen sin_carnet_hogar = max(sin_carnet_ind)
label var sin_carnet_hogar "Privación: sin documento de identidad (hogar)"

*-------------------------------------------------------------*
* 2. Analfabetismo: personas ≥15 años que no saben leer
*-------------------------------------------------------------*
gen analfabetismo_a = .
replace analfabetismo_a = 1 if p25 >= 15 & p35 == 2
replace analfabetismo_a = 0 if p25 >= 15 & p35 == 1
replace analfabetismo_a = . if inlist(p35,0,9)
bys vivienda_ref_id: egen analfabetismo_hogar_a = max(analfabetismo_a)
label var analfabetismo_hogar_a "Privación: analfabetismo (A, 0 y 9 missing)"

gen analfabetismo_b = .
replace analfabetismo_b = 1 if p25 >= 15 & inlist(p35,2,9)
replace analfabetismo_b = 0 if p25 >= 15 & p35 == 1
replace analfabetismo_b = . if p35 == 0
bys vivienda_ref_id: egen analfabetismo_hogar_b = max(analfabetismo_b)
label var analfabetismo_hogar_b "Privación: analfabetismo (B, 9 = no sabe, 0 missing)"

*-------------------------------------------------------------*
* 3. Comunicación: hogar sin teléfono fijo ni celular
*-------------------------------------------------------------*
gen comunicacion_hogar = .
replace comunicacion_hogar = 1 if p17e == 2
replace comunicacion_hogar = 0 if p17e == 1
replace comunicacion_hogar = . if inlist(p17e,0,9)
label var comunicacion_hogar "Privación: sin teléfono fijo ni celular"

**************************************************************
* DIMENSIÓN 2: RECURSOS
**************************************************************

*-------------------------------------------------------------*
* 4. Agua potable: hogar sin agua potable
*-------------------------------------------------------------*
gen priv_agua_potable = .
replace priv_agua_potable = 1 if inlist(p07,5,6,7)
replace priv_agua_potable = 0 if inlist(p07,1,2,3,4)
replace priv_agua_potable = . if inlist(p07,0,9)
label var priv_agua_potable "Privación: hogar sin agua potable"

*-------------------------------------------------------------*
* 5. Electricidad: hogar sin electricidad
*-------------------------------------------------------------*
gen priv_electricidad = .
replace priv_electricidad = 1 if inlist(p11,4,5)
replace priv_electricidad = 0 if inlist(p11,1,2,3)
replace priv_electricidad = . if inlist(p11,0,9)
label var priv_electricidad "Privación: hogar sin electricidad"

*-------------------------------------------------------------*
* 6. Saneamiento básico: hogar sin baño o sin desagüe adecuado
*-------------------------------------------------------------*
gen priv_saneamiento = .
replace priv_saneamiento = 1 if p09 == 3
replace priv_saneamiento = 0 if inlist(p09,1,2)
replace priv_saneamiento = . if inlist(p09,0,9)
label var priv_saneamiento "Privación: hogar sin saneamiento básico"

**************************************************************
* DIMENSIÓN 3: OPORTUNIDADES Y ELECCIÓN
**************************************************************

*-------------------------------------------------------------*
* 7. Salud: parto no atendido en centro de salud
*-------------------------------------------------------------*
gen parto_no_salud_ind = .
replace parto_no_salud_ind = 1 if inlist(p49b,2,3)
replace parto_no_salud_ind = 0 if p49b == 1
replace parto_no_salud_ind = . if inlist(p49b,0,9)
bys vivienda_ref_id: egen parto_no_salud_hogar = max(parto_no_salud_ind)
label var parto_no_salud_hogar "Privación: parto fuera de centro de salud"

*-------------------------------------------------------------*
* 8. Embarazo adolescente: al menos un embarazo 15–19 años
*-------------------------------------------------------------*
gen embarazo_adolescente_ind = .
replace embarazo_adolescente_ind = 1 if p25 >= 15 & p25 <= 19 & p46 > 0
replace embarazo_adolescente_ind = 0 if p25 >= 15 & p25 <= 19 & p46 == 0
replace embarazo_adolescente_ind = . if inlist(p46,0,9)
bys vivienda_ref_id: egen embarazo_adolescente_hogar = max(embarazo_adolescente_ind)
label var embarazo_adolescente_hogar "Privación: embarazo adolescente (hogar)"

*-------------------------------------------------------------*
* 9. Educación: niño/a 6–19 años que no asiste a la escuela
*-------------------------------------------------------------*
gen sin_asistencia_ind = .
replace sin_asistencia_ind = 1 if p25 >= 6 & p25 <= 19 & p36 == 4
replace sin_asistencia_ind = 0 if p25 >= 6 & p25 <= 19 & inlist(p36,1,2,3)
replace sin_asistencia_ind = . if inlist(p36,0,9)
bys vivienda_ref_id: egen sin_asistencia_hogar = max(sin_asistencia_ind)
label var sin_asistencia_hogar "Privación: niño/a 6–19 años no asiste (hogar)"

**************************************************************
* REORDENAR Y GUARDAR BASE FINAL
**************************************************************

order munic_ref_id urbrur vivienda_ref_id ///
      sin_carnet_hogar analfabetismo_hogar_a analfabetismo_hogar_b comunicacion_hogar ///
      priv_agua_potable priv_electricidad priv_saneamiento ///
      parto_no_salud_hogar embarazo_adolescente_hogar sin_asistencia_hogar

compress
save "$path\censo_2012_privaciones.dta", replace
display "Base con las 9 privaciones (0 y 9 = missing) guardada correctamente en $path"

**************************************************************
* FIN DEL SCRIPT
**************************************************************
