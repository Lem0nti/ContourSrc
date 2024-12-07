@echo off
cd %~dp0
cls
chcp 65001 > nul
setlocal EnableDelayedExpansion

if exist Create.sql del /f /q Create.sql > nul

type utf-8bom >> Create.sql

rem Записываем в файл в порядке Таблицы -> Ключи -> Индексы -> Начальные данные
rem и добавляем после каждого файла новую строку
for %%f in (Tables.sql FKeys.sql Indexes.sql StartData.sql) do (
    findstr /I /B /M /G:utf-8bom %%f > nul
    if !ERRORLEVEL!==0 (set is_bom=1) else (set is_bom=0)

    if !is_bom!==1 (
        set ff=%%f
        echo BOM deleted !ff!
        set /a "count=0"
        for /f "delims=" %%s in (%%f) do (
            set ss=%%s
            set /a count+=1
            if !count!==1 (
                set out_str=!ss:~1!
            ) else (
                set out_str=!ss!  
            )
            echo(!out_str! >> Create.sql
        )
    ) else (
        type %%f >> Create.sql
    )
    echo. >> Create.sql
    echo Script %%f added
)

echo Base scripts added

rem Записываем в файл функции
rem и добавляем после каждого файла новую строку
for %%f in (.\Functions\*.sql)do ( 
    findstr /I /B /M /G:utf-8bom %%f > nul
    if !ERRORLEVEL!==0 (set is_bom=1) else (set is_bom=0)

    if !is_bom!==1 (
        set ff=%%f
        echo BOM deleted !ff!
        set /a "count=0"
        for /f "delims=" %%s in (%%f) do (
            set ss=%%s
            set /a count+=1
            if !count!==1 (
                set out_str=!ss:~1!
            ) else (
                set out_str=!ss!  
            )
            echo(!out_str! >> Create.sql
        )
    ) else (
        type %%f >> Create.sql
    )
    echo. >> Create.sql
    echo Function %%f added
)

echo Functions added

rem Записываем в файл вьюхи
rem и добавляем после каждого файла новую строку
for %%f in (.\Views\*.sql) do ( 
    findstr /I /B /M /G:utf-8bom %%f > nul
    if !ERRORLEVEL!==0 (set is_bom=1) else (set is_bom=0)

    if !is_bom!==1 (
        set ff=%%f
        echo BOM deleted !ff!
        set /a "count=0"
        for /f "delims=" %%s in (%%f) do (
            set ss=%%s
            set /a count+=1
            if !count!==1 (
                set out_str=!ss:~1!
            ) else (
                set out_str=!ss!  
            )
            echo(!out_str! >> Create.sql
        )
    ) else (
        type %%f >> Create.sql
    )
    echo. >> Create.sql
    echo View %%f added
) 

echo Views added

rem Записываем в файл процедуры
rem и добавляем после каждого файла новую строку
for %%f in (.\Procedures\*.sql) do ( 
    findstr /I /B /M /G:..\_db\utf-8bom %%f > nul
    if !ERRORLEVEL!==0 (set is_bom=1) else (set is_bom=0)

    if !is_bom!==1 (
        set ff=%%f
        echo BOM deleted !ff!
        set /a "count=0"
        for /f "delims=" %%s in (%%f) do (
            set ss=%%s
            set /a count+=1
            if !count!==1 (
                set out_str=!ss:~1!
            ) else (
                set out_str=!ss!  
            )
            echo(!out_str! >> Create.sql
        )
    ) else (
        type %%f >> Create.sql
    )
    echo. >> Create.sql
    echo Procedure %%f added
)   
echo Procedures added

for %%f in (Version.sql) do (
    findstr /I /B /M /G:utf-8bom %%f > nul
    if !ERRORLEVEL!==0 (set is_bom=1) else (set is_bom=0)

    if !is_bom!==1 (
        set ff=%%f
        echo BOM deleted !ff!
        set /a "count=0"
        for /f "delims=" %%s in (%%f) do (
            set ss=%%s
            set /a count+=1
            if !count!==1 (
                set out_str=!ss:~1!
            ) else (
                set out_str=!ss!  
            )
            echo(!out_str! >> Create.sql
        )
    ) else (
        type %%f >> Create.sql
    )
    echo. >> Create.sql
    echo Script %%f added
)

echo Version added