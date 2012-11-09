#include "stdafx.h"
#include "Form1.h"
#include <string>
#include <cctype>
#include "msclr/marshal.h"
#include "msclr/marshal_cppstd.h"
#include "data.h"

static System::String ^longFormOf (char c)
{
	System::String ^result;
	char s[2];
	switch(c){
		case 't':
			result = L"<tab>";
			break;
		case 'c':
			result = L"<caps lock>";
			break;
		case 'l':
			result = L"<left shift>";
			break;
		case 'r':
			result = L"<right shift>";
			break;
		default:
			s[0] = c;
			s[1] = '\0';
			result = gcnew System::String(s);
	}
	return result;
}

static System::String ^longFormOf2 (char c1, char c2)
{
	System::String ^s1 = longFormOf(c1);
	System::String ^s2 = longFormOf(c2);
	System::String ^result;
	if(islower(c1) || islower(c2)){
		result = s1 + L" " + s2;
	}else{
		result = s1 + s2;
	}
	return result;
}

static key_t keyOfSightOrder(hand_t hand, int i)
{
	return (hand == handLeft) ? ((i / 6) * 6) + (5 - (i % 6)) : keyNumOfHand + i;
}

static System::Windows::Forms::Keys LeftOrRightShiftKey();

static key_t keyOfKeyCode(System::Windows::Forms::Keys code)
{
	switch(code){
	case System::Windows::Forms::Keys::Oemtilde:
		return keyBackQuote;
	case System::Windows::Forms::Keys::D1:
		return key1;
	case System::Windows::Forms::Keys::D2:
		return key2;
	case System::Windows::Forms::Keys::D3:
		return key3;
	case System::Windows::Forms::Keys::D4:
		return key4;
	case System::Windows::Forms::Keys::D5:
		return key5;
	case System::Windows::Forms::Keys::Tab:
		return keyTab;
	case System::Windows::Forms::Keys::Q:
		return keyQ;
	case System::Windows::Forms::Keys::W:
		return keyW;
	case System::Windows::Forms::Keys::E:
		return keyE;
	case System::Windows::Forms::Keys::R:
		return keyR;
	case System::Windows::Forms::Keys::T:
		return keyT;
	case System::Windows::Forms::Keys::Capital:
		return keyCapsLock;
	case System::Windows::Forms::Keys::A:
		return keyA;
	case System::Windows::Forms::Keys::S:
		return keyS;
	case System::Windows::Forms::Keys::D:
		return keyD;
	case System::Windows::Forms::Keys::F:
		return keyF;
	case System::Windows::Forms::Keys::G:
		return keyG;
	case System::Windows::Forms::Keys::LShiftKey:
		return keyLeftShift;
	case System::Windows::Forms::Keys::Z:
		return keyZ;
	case System::Windows::Forms::Keys::X:
		return keyX;
	case System::Windows::Forms::Keys::C:
		return keyC;
	case System::Windows::Forms::Keys::V:
		return keyV;
	case System::Windows::Forms::Keys::B:
		return keyB;
	case System::Windows::Forms::Keys::D6:
		return key6;
	case System::Windows::Forms::Keys::D7:
		return key7;
	case System::Windows::Forms::Keys::D8:
		return key8;
	case System::Windows::Forms::Keys::D9:
		return key9;
	case System::Windows::Forms::Keys::D0:
		return key0;
	case System::Windows::Forms::Keys::OemMinus:
		return keyHyphen;
	case System::Windows::Forms::Keys::Y:
		return keyY;
	case System::Windows::Forms::Keys::U:
		return keyU;
	case System::Windows::Forms::Keys::I:
		return keyI;
	case System::Windows::Forms::Keys::O:
		return keyO;
	case System::Windows::Forms::Keys::P:
		return keyP;
	case System::Windows::Forms::Keys::OemOpenBrackets:
		return keyOpenBracket;
	case System::Windows::Forms::Keys::H:
		return keyH;
	case System::Windows::Forms::Keys::J:
		return keyJ;
	case System::Windows::Forms::Keys::K:
		return keyK;
	case System::Windows::Forms::Keys::L:
		return keyL;
	case System::Windows::Forms::Keys::OemSemicolon:
		return keySemicolon;
	case System::Windows::Forms::Keys::OemQuotes:
		return keyApostrophe;
	case System::Windows::Forms::Keys::N:
		return keyN;
	case System::Windows::Forms::Keys::M:
		return keyM;
	case System::Windows::Forms::Keys::Oemcomma:
		return keyComma;
	case System::Windows::Forms::Keys::OemPeriod:
		return keyPeriod;
	case System::Windows::Forms::Keys::OemQuestion:
		return keySlash;
	case System::Windows::Forms::Keys::RShiftKey:
		return keyRightShift;
	default:
		return -1;
	}
}

namespace measuring {

	void Form1::InitializeData()
	{
		data = new data_t;
		::init_data(data);

		inputed = L"";
		firstTime = nullptr;

		fileName = nullptr;
	}

	void Form1::FinalizeData()
	{
		delete data;
	}

	void Form1::InitializeTable()
	{
		InitializeTable(leftDataGridView, handLeft);
		InitializeTable(rightDataGridView, handRight);
		/* fill */
		UpdateTable();
	}

	void Form1::InitializeTable(System::Windows::Forms::DataGridView^ view, enum hand hand)
	{
		view->ColumnCount = keyNumOfHand;
		/* column headers */
		for(int i = 0; i < keyNumOfHand; ++i){
			key_t key = keyOfSightOrder(hand, i);
			char s[2];
			s[0] = charOfKey(key);
			s[1] = '\0';
			view->Columns[i]->Name = gcnew System::String(s);
		}
		/* row headers */
		view->RowCount = keyNumOfHand;
		for(int i = 0; i < keyNumOfHand; ++i){
			key_t key = keyOfSightOrder(hand, i);
			char s[2];
			s[0] = charOfKey(key);
			s[1] = '\0';
			view->Rows[i]->HeaderCell->Value = gcnew System::String(s);
		}
	}

	void Form1::UpdateTable()
	{
		UpdateTable(leftDataGridView, handLeft);
		UpdateTable(rightDataGridView, handRight);
	}

	void Form1::UpdateTable(System::Windows::Forms::DataGridView^ view, enum hand hand)
	{
		for(int i = 0; i < keyNumOfHand; ++i){
			key_t fst = keyOfSightOrder(hand, i);
			for(int j = 0; j < keyNumOfHand; ++j){
				key_t snd = keyOfSightOrder(hand, j);
				key_pair_t pair = {fst, snd};
				int32_t msec = ::msecOf(data, pair);
				view->Rows[i]->Cells[j]->Value = msec;
			}
		}
	}

	void Form1::ReadyMeasuring()
	{
		/* 測定の準備をする */
		key_pair_t pair = ::wanted(data);
		System::String ^s = longFormOf2(charOfKey(pair.first), charOfKey(pair.second));
		guideLabel->Text = s;
		/* 修正モードをとりあえず色で表示 */
		if(::is_fixing_mode(data)){
			inputTextBox->BackColor = System::Drawing::Color::LightPink;
		}else{
			inputTextBox->BackColor = System::Drawing::Color::Azure;
		}
	}

	void Form1::loadFromFile(System::String ^newFileName)
	{
		std::string newFileName_str = msclr::interop::marshal_as<std::string>(newFileName);

		if(::loadFromFile(data, newFileName_str.c_str())){
			/* 成功したのでファイル名を置き換え */
			fileName = newFileName;
			/* 問題差し替え */
			ReadyMeasuring();
			/* 再描画 */
			UpdateTable();
		}else{
			 System::Windows::Forms::MessageBox::Show(
					newFileName,
					L"error!",
					System::Windows::Forms::MessageBoxButtons::OK,
					System::Windows::Forms::MessageBoxIcon::Error);
		}
	}

	void Form1::saveToFile(System::String ^newFileName)
	{
		std::string newFileName_str = msclr::interop::marshal_as<std::string>(newFileName);

		if(::saveToFile(data, newFileName_str.c_str())){
			fileName = newFileName;
		}else{
			 System::Windows::Forms::MessageBox::Show(
					newFileName,
					L"error!",
					System::Windows::Forms::MessageBoxButtons::OK,
					System::Windows::Forms::MessageBoxIcon::Error);
		}
	}

	/* event handlers */

	System::Void Form1::inputTextBox_KeyDown(System::Object^  sender, System::Windows::Forms::KeyEventArgs^  e)
	{
		System::Windows::Forms::Keys code = e->KeyCode;
		if(code == System::Windows::Forms::Keys::ShiftKey){
			code = LeftOrRightShiftKey();
		}
		key_t key = keyOfKeyCode(code);
		if(key >= 0){
			key_pair_t wanted = ::wanted(data);
			if(firstTime != nullptr && key == wanted.second){
				/* 時間 */
				System::DateTime ^secondTime = System::DateTime::Now;
				System::TimeSpan ^interval = *secondTime - *firstTime;
				int32_t msec = interval->Milliseconds;
				/* データ追加 */
				::add(data, wanted, msec);
				/* 完成 */
				inputed = longFormOf2(charOfKey(wanted.first), charOfKey(wanted.second));
				/* 時間クリア */
				firstTime = nullptr;
				/* 次の問題 */
				ReadyMeasuring();
				/* 再描画 */
				inputTextBox->Text = inputed;
				inputTextBox->SelectionStart = inputed->Length;
				if(::handOf(wanted.second) == handLeft){
					UpdateTable(leftDataGridView, handLeft);
				}else{
					UpdateTable(rightDataGridView, handRight);
				}
			}else if(key == wanted.first){
				/* 入力文字 */
				inputed = longFormOf(charOfKey(key));
				/* 時間 */
				firstTime = System::DateTime::Now;
				/* 再描画 */
				inputTextBox->Text = inputed;
				inputTextBox->SelectionStart = inputed->Length;
			}else{
				/* キャンセル */
				inputed = L"";
				firstTime = nullptr;
				/* 再描画 */
				inputTextBox->Text = inputed;
			}
		}
	}

	System::Void Form1::closeToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e)
	{
		Close();
	}

	System::Void Form1::openToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e)
	{
		if(fileName != nullptr){
			openFileDialog->FileName = fileName;
		}
		System::Windows::Forms::DialogResult result = openFileDialog->ShowDialog();
		if(result == System::Windows::Forms::DialogResult::OK){
			loadFromFile(openFileDialog->FileName);
		}
	}

	System::Void Form1::saveToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e)
	{
		if(fileName != nullptr){
			saveToFile(fileName);
		}else{
			saveAsToolStripMenuItem_Click(sender, e);
		}
	}

	System::Void Form1::saveAsToolStripMenuItem_Click(System::Object^  sender, System::EventArgs^  e)
	{
		if(fileName != nullptr){
			saveFileDialog->FileName = fileName;
		}
		System::Windows::Forms::DialogResult result = saveFileDialog->ShowDialog();
		if(result == System::Windows::Forms::DialogResult::OK){
			saveToFile(saveFileDialog->FileName);
		}
	}
}

/* hacks */

#pragma comment(lib, "user32.lib")
#include <windows.h>

static System::Windows::Forms::Keys LeftOrRightShiftKey()
{
	if(GetKeyState(VK_LSHIFT) & 0x8000){
		return System::Windows::Forms::Keys::LShiftKey;
	}else if(GetKeyState(VK_RSHIFT) & 0x8000){
		return System::Windows::Forms::Keys::RShiftKey;
	}else{
		return System::Windows::Forms::Keys::None;
	}
}
