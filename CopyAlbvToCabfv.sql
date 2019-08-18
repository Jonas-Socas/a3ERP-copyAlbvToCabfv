USE [horican]
GO
/****** Object:  Trigger [dbo].[HORICAN_COPIAR_ALBV]    Script Date: 14/08/2019 8:57:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[HORICAN_COPIAR_ALBV]
ON [dbo].[LINEFACT]
AFTER INSERT
AS
begin
if (select top 1 inserted.comven from inserted) = 'v'
begin try
	declare @idfacv as money
	declare @idalbv as money
	declare @numdoc as smallint
	declare @fecha as date
	declare @serie as varchar(8)
	declare @fechavto as date
	declare @primerlapso as smallint
	declare @codcli as varchar(8)
	declare @nomcli as varchar(100)
	declare @descapu as varchar(100)
	declare @comven as varchar(1)
	
	select top 1 @comven = inserted.comven from inserted
	select top 1 @idfacv = inserted.idfacv from inserted
	select @codcli = cabefacv.codcli from cabefacv where cabefacv.idfacv = @idfacv
	select @primerlapso = primlapso from formapag, clientes where clientes.forpag = formapag.forpag and clientes.codcli = @codcli
	select @idalbv = LINEALBA.idalbv from linealba, linefact where linealba.idalbv = linefact.idalbv and linefact.idfacv = @idfacv
	select @numdoc = cabealbv.numdoc, @fecha = cabealbv.fecha, @fechavto = dateadd(day, @primerlapso, cabealbv.fecha), @serie = cabealbv.serie from cabealbv where cabealbv.idalbv = @idalbv
	select @nomcli = clientes.nomcli from clientes where clientes.codcli = @codcli
	update cabefacv
	set
		cabefacv.numdoc = @numdoc,
		cabefacv.fecha = @fecha,
		cabefacv.serie = @serie
	where cabefacv.idfacv = @idfacv and @comven = 'v'
	update cartera
		set cartera.fecha = @fechavto,
		cartera.fechavalor = @fechavto,
		cartera.numdoc = cast(@numdoc as varchar),
		cartera.serie = @serie,
		cartera.fechafactura = @fecha,
		cartera.fechacalc = @fechavto,
		cartera.fechacalculovto = @fecha,
		cartera.fechariesgo = @fecha
	where cartera.procedeid = @idfacv and cartera.cobpag = 'c'
	if (@serie is null)
		set @descapu = concat('De n/fra. ', @numdoc, ' (', @nomcli, ')')
	else
		set @descapu = concat('De n/fra. ', ltrim(@serie), '/', @numdoc, ' (', @nomcli, ')')
	update apuntes
	set
		apuntes.fecha = @fecha,
		apuntes.FECHAMOD = @fecha,
		apuntes.FECHAVALOR = @fecha,
		apuntes.descapu = @descapu
	where apuntes.procedeid = @idfacv and apuntes.procede = 'fv'
end try
BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH
end
