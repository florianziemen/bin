      program difftop
c      
      parameter(ie=2160,je=1080)
c
      dimension top(ie,je),ao(ie,je),an(ie,je),ihead(4)
c
      read(70)ihead
      read(70)top
      write (6,*)ihead
c
      do j=1,je
         do i=1,ie
            if(top(i,j).lt.-4000.)then
               ao(i,j)=9.
            elseif(top(i,j).lt.0.)then
               ao(i,j)=1.
            else
               ao(i,j)=0.
            endif
            an(i,j)=ao(i,j)
         enddo
      enddo
      write(71)0,1,1,ie*je
      write(71)an

      iter=0
 10   iter=iter+1
      zaehl=0
  
      do j=1,je
         jo=j-1
         if(j.eq.1)jo=1
         ju=j+1
         if(j.eq.je)ju=je
         do i=1,ie
            il=i-1
            if(il.lt.1)il=ie
            ir=i+1
            if(ir.gt.ie)ir=1
            zzz=an(i,j)
            if(an(i,j).eq.1.)an(i,j)=max(an(il,j),an(ir,j),an(i,jo)
     x           ,an(i,ju),an(il,ju),an(ir,ju),an(il,jo),an(ir,jo))
            if(an(i,j).ne.zzz)zaehl=zaehl+1
         enddo
      enddo



      write(6,*)zaehl
cc      write(71)iter,1,1,ie*je
cc      write(71)an
      do j=je,1,-1
         jo=j-1
         if(j.eq.1)jo=1
         ju=j+1
         if(j.eq.je)ju=je
         do i=ie,1,-1
            il=i-1
            if(il.lt.1)il=ie
            ir=i+1
            if(ir.gt.ie)ir=1
            zzz=an(i,j)
            if(an(i,j).eq.1.)an(i,j)=max(an(il,j),an(ir,j),an(i,jo)
     x           ,an(i,ju),an(il,ju),an(ir,ju),an(il,jo),an(ir,jo))
            if(an(i,j).ne.zzz)zaehl=zaehl+1
         enddo
       enddo


       write(6,*)zaehl
cc      write(71)iter,1,1,ie*je
cc      write(71)an


      do j=je,1,-1
         jo=j-1
         if(j.eq.1)jo=1
         ju=j+1
         if(j.eq.je)ju=je
         do i=1,ie
            il=i-1
            if(il.lt.1)il=ie
            ir=i+1
            if(ir.gt.ie)ir=1
            zzz=an(i,j)
            if(an(i,j).eq.1.)an(i,j)=max(an(il,j),an(ir,j),an(i,jo)
     x           ,an(i,ju),an(il,ju),an(ir,ju),an(il,jo),an(ir,jo))
            if(an(i,j).ne.zzz)zaehl=zaehl+1
         enddo
      enddo
      write(6,*)zaehl
cc      write(71)iter,1,1,ie*je
cc      write(71)an
      do j=1,je
         jo=j-1
         if(j.eq.1)jo=1
         ju=j+1
         if(j.eq.je)ju=je
         do i=ie,1,-1
            il=i-1
            if(il.lt.1)il=ie
            ir=i+1
            if(ir.gt.ie)ir=1
            zzz=an(i,j)
            if(an(i,j).eq.1.)an(i,j)=max(an(il,j),an(ir,j),an(i,jo)
     x           ,an(i,ju),an(il,ju),an(ir,ju),an(il,jo),an(ir,jo))
            if(an(i,j).ne.zzz)zaehl=zaehl+1
         enddo
      enddo
      write(6,*)zaehl
      write(71)iter,1,1,ie*je
      write(71)an
      if(zaehl.gt.0.5)goto 10
      
c     
      stop
      end
      
