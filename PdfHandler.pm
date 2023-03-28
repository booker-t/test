package XPortal::PdfHandler;

use XPortal::Settings;

use Inline (
  Java => << "END_JAVA",
import com.lowagie.text.pdf.*;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Rectangle;

import java.util.*;
import java.io.*;
import java.nio.charset.Charset;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;

public class PDF {
	private String file;
	private PdfReader reader;
	private HashMap hash = new HashMap();
	private Rectangle pageSizes;
	private static final String defaultCharset = "UTF-8";

	public PDF (String file) {
		this.file = file;

		try {
			reader = new PdfReader(file);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private static String doEncodeData(String data) {
		Charset cs = Charset.forName(defaultCharset);
		ByteBuffer bb = cs.encode(data);
		CharBuffer charbuf=Charset.forName(defaultCharset).decode(bb);
		return charbuf.toString();
	}

	public void setAuthor(String author) {
		String encoded = doEncodeData(author);
		hash.put("Author",encoded);
	}

	public Object getAuthor() {
		return hash.get((Object) "Author");
	}

	public void setSubject(String subject) {
		String encoded = doEncodeData(subject);
		hash.put("Subject",encoded);
	}

	public Object getSubject() {
		return hash.get((Object) "Subject");
	}

	public void setCreator(String creator) {
		String encoded = doEncodeData(creator);
		hash.put("Creator",encoded);
	}

	public Object getCreator() {
		return hash.get((Object) "Creator");
	}

	public void setKeywords(String keywords) {
		String encoded = doEncodeData(keywords);
		hash.put("Keywords",encoded);
	}

	public Object getKeywords() {
		return hash.get((Object) "Keywords");
	}

	public void setTitle(String title){
		String encoded = doEncodeData(title);
		hash.put("Title",encoded);
	}

	public Object getTitle() {
		return hash.get((Object) "Title");
	}

	public void rewritePDF(String newFile) {
		try {
			int n = getPdfPagesCount();
			Document document = new Document(reader.getPageSize(1));
			PdfCopy copy = new PdfCopy(document, new FileOutputStream(newFile));
			//copy.setXmpMetadata(reader.getMetadata());
			document.open();

			if (!hash.isEmpty()) {
				Object[] arr = hash.keySet().toArray();

				for (int i = 0; i < arr.length; i++) {
					if (arr[i].equals("Author")) {
						document.addAuthor((String) hash.get("Author"));
					} else if(arr[i].equals("Subject")) {
						document.addSubject((String) hash.get("Subject"));
					} else if(arr[i].equals("Creator")) {
						document.addCreator((String) hash.get("Creator"));
					} else if (arr[i].equals("Keywords")) {
						document.addKeywords((String) hash.get("Keywords"));
					} else if (arr[i].equals("Title")) {
						document.addTitle((String) hash.get("Title"));
					}
				}
			}

			int i = 1;

			while (i <= n) {
				document.setPageSize(reader.getPageSize(i));
				PdfImportedPage page = copy.getImportedPage(reader, i);
				copy.addPage(page);
				i++;
			}

			document.close();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (DocumentException e) {
			e.printStackTrace();
		}
	}

	public void readPDFMetaData() {
		hash = reader.getInfo();
	}

	public int getPdfPagesCount() {
		return reader.getNumberOfPages();
	}

	public void readPageSize() {
		int n = getPdfPagesCount();
		int i = Math.round((float)(n/2 + 0.5));
		pageSizes = reader.getPageSizeWithRotation(i);
	}

	public float getPageHeight() {
		return pageSizes.getHeight();
	}

	public float getPageWidth() {
		return pageSizes.getWidth();
	}

	public int checkAllPagesSize() {
		int n = getPdfPagesCount();
		double pageHeight = 0.0;
		double pageWidth = 0.0;
		for (int i = 1; i <= n; i++) {
			Rectangle pageSize = reader.getPageSizeWithRotation(i);
			if (i == 1) {
				pageHeight = pageSize.getHeight();
				pageWidth = pageSize.getWidth();
			} else {
				if (Math.abs(pageSize.getHeight() - pageHeight) > 3) {
					return 0;
				}
				if (Math.abs(pageSize.getWidth() - pageWidth) > 3) {
					return 0;
				}
			}
		}
		return 1;
	}
}
END_JAVA
J2SDK => $XPortal::Settings::JavaJDKPath,
PACKAGE => 'XPortal::PdfHandler',
CLASSPATH => $XPortal::Settings::ForPDFJavaLibrary,
EXTRA_JAVA_ARGS => '-Xmx96m',
SHARED_JVM => 1
);

use Inline::Java qw(caught);
use Encode;

my $pdf;

sub RewritePDFDescription {
	my $OldFile = shift;
	my $Author = shift;
	my $Subject = shift;
	my $Title = shift;
	my $Keywords = shift;
	my $Creator = shift || "FictionHub Technologies - http://www.litres.ru";
	my $NewFile = $OldFile.".pdf";

	eval {
		$pdf = new XPortal::PdfHandler::PDF($OldFile);
		$pdf -> setAuthor(XPortal::General::DecodeUtf8($Author)) if $Author;
		$pdf -> setSubject(XPortal::General::DecodeUtf8($Subject)) if $Subject;
		$pdf -> setCreator(XPortal::General::DecodeUtf8($Creator)) if $Creator;
		$pdf -> setKeywords(XPortal::General::DecodeUtf8($Keywords)) if $Keywords;
		$pdf -> setTitle(XPortal::General::DecodeUtf8($Title)) if $Title;
		$pdf -> rewritePDF($NewFile);
	};

	if ($@) {
		if (caught("java.lang.Exception")) {
			my $msg = $@ -> getMessage();
			return $msg;
		} else {
			return $@;
		}
	} else {
		if (-e $NewFile && -s $NewFile) {
			unlink $OldFile;
			rename $NewFile, $OldFile;
		} else {
			return "Проблема при редактировании файла! Обновленный файл не создан!";
		}
	}
	return undef;
}

sub ReadPDFFileData {
	my $PdfFile = shift;

	eval {
		$pdf = new XPortal::PdfHandler::PDF($PdfFile);
		$pdf -> readPDFMetaData();
		$pdf -> readPageSize();
	};

	if ($@) {
		if (caught("java.lang.Exception")) {
			my $msg = $@ -> getMessage();
			return $msg;
		} else {
			return $@;
		}
	}
	return undef;
}

sub GetAuthor {
	return $pdf -> getAuthor() if $pdf;
}

sub GetSubject {
	return $pdf -> getSubject() if $pdf;
}

sub GetCreator {
	return $pdf -> getCreator() if $pdf;
}

sub GetKeywords {
	return $pdf -> getKeywords() if $pdf;
}

sub GetTitle {
	return $pdf -> getTitle() if $pdf;
}

sub GetPageCount {
	return $pdf -> getPdfPagesCount() if $pdf;
}

sub GetPageHeight {
	return $pdf -> getPageHeight() if $pdf;
}

sub GetPageWidth {
	return $pdf -> getPageWidth() if $pdf;
}

sub CheckAllPages {
	return $pdf -> checkAllPagesSize() if $pdf;
}

END {
	my @Directs;
	push @Directs, "$XPortal::Settings::Path/cgi/_Inline";

	for my $directory (@Directs) {
		opendir(DIR, $directory);
		my @files = grep(!/^\.$|^\.\.$/, readdir DIR);
		for (@files) {
			push @Directs, "$directory/$_" if -d $directory."/".$_;
			unlink "$directory/$_" if -e $directory."/".$_;
		}
		closedir(DIR);
	}

	rmdir $_ for reverse @Directs;
}

1;
